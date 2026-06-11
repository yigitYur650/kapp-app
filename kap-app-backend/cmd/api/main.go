package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"assignment-backend/internal/config"
	"assignment-backend/internal/middleware"
	"assignment-backend/internal/modules/auth"
	"assignment-backend/internal/modules/product"
	"assignment-backend/internal/modules/tenant"
)

func main() {
	// 1. Veritabanı bağlantı havuzunu başlat.
	db := config.NewDatabase()
	defer db.Close()

	// 2. JWT secret'ı çevre değişkeninden yükle.
	middleware.InitJWTSecret()

	// 3. Router'ı kur ve rotaları bağla.
	mux := http.NewServeMux()
	registerRoutes(mux, db)

	// 4. Sunucu portunu env'den oku; varsayılan 8080.
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	addr := fmt.Sprintf(":%s", port)
	log.Printf("Kap-App backend %s adresinde dinleniyor...", addr)

	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatalf("main.ListenAndServe: sunucu başlatılamadı: %v", err)
	}
}

// registerRoutes, tüm HTTP rotalarını mux'a kaydeder.
// Public ve korunan rotalar burada ayrıştırılır.
// db parametresi, modül repository'leri için bağımlılık enjeksiyonu sağlar.
func registerRoutes(mux *http.ServeMux, db *config.Database) {
	// ── Public rotalar ────────────────────────────────────────────
	mux.HandleFunc("GET /health", handleHealth)

	// ── Korunan rotalar (AuthMiddleware zinciri) ──────────────────
	mux.Handle("GET /api/v1/me", middleware.AuthMiddleware(http.HandlerFunc(handleMe)))

	// ── Auth modülü ───────────────────────────────────────────────
	authRepo := auth.NewRepository(db.Pool)
	authSvc := auth.NewService(authRepo)
	auth.NewHandler(authSvc).RegisterRoutes(mux)

	// ── Tenant modülü ─────────────────────────────────────────────
	tenantRepo := tenant.NewRepository(db.Pool)
	tenantSvc := tenant.NewService(tenantRepo)
	tenant.NewHandler(tenantSvc).RegisterRoutes(mux)

	// ── Product modülü ────────────────────────────────────────────
	// POST   /api/v1/products               → ürün ekle
	// GET    /api/v1/products?tenant_id=... → ürün listele
	// PATCH  /api/v1/products/{id}/status   → durum güncelle
	// DELETE /api/v1/products/{id}          → ürün sil
	productRepo := product.NewRepository(db.Pool)
	productSvc := product.NewService(productRepo)
	product.NewHandler(productSvc).RegisterRoutes(mux)
}

// handleHealth, yük dengeleyiciler ve monitoring için basit sağlık kontrolü döner.
// Auth gerektirmez.
func handleHealth(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

// handleMe, AuthMiddleware'in context'e gömdüğü userID'yi okuyarak döner.
// Bu rota yalnızca geçerli JWT ile erişilebilir; test ve geliştirme amaçlıdır.
func handleMe(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		// AuthMiddleware bypass edilmeden buraya gelinemez — defensive check.
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "yetkisiz"})
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"user_id": userID})
}

// writeJSON, w'ye Content-Type: application/json başlığını ve JSON gövdesini yazar.
func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(v); err != nil {
		log.Printf("main.writeJSON: encode hatası: %v", err)
	}
}
