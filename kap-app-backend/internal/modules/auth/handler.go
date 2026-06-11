package auth

import (
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"
	"strings"
	"unicode/utf8"

	"assignment-backend/internal/middleware"
)

// Handler, auth modülünün HTTP katmanını taşır.
type Handler struct {
	svc *Service
}

// NewHandler, Handler örneği oluşturur.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// RegisterRoutes, auth modülüne ait rotaları mux'a kaydeder.
// main.go içindeki registerRoutes() tarafından çağrılır.
func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.Handle(
		"POST /api/v1/auth/sync-profile",
		middleware.AuthMiddleware(http.HandlerFunc(h.handleSyncProfile)),
	)
}

// syncProfileRequest, POST /api/v1/auth/sync-profile istek gövdesidir.
type syncProfileRequest struct {
	DisplayName string `json:"display_name"`
}

// handleSyncProfile, JWT'deki userID + body'deki display_name ile profil senkronizasyonu yapar.
//
// Başarı  → 200 OK    { user_id, slug_id, display_name, is_new }
// Hata    → 400 / 401 / 500  { error: "..." } (maskelenmiş)
func (h *Handler) handleSyncProfile(w http.ResponseWriter, r *http.Request) {
	// 1. userID context'ten okunur (AuthMiddleware garantisi).
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		writeJSON(w, http.StatusUnauthorized, errBody("yetkisiz"))
		return
	}

	// 2. İstek gövdesini oku (max 1 MB — kötü niyetli büyük payload koruması).
	body, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
	if err != nil {
		log.Printf("auth.handleSyncProfile: body okunamadı: %v", err)
		writeJSON(w, http.StatusBadRequest, errBody("İstek gövdesi okunamadı."))
		return
	}
	defer r.Body.Close()

	// 3. JSON çözümle.
	var req syncProfileRequest
	if err := json.Unmarshal(body, &req); err != nil {
		log.Printf("auth.handleSyncProfile: json unmarshal: %v", err)
		writeJSON(w, http.StatusBadRequest, errBody("Geçersiz JSON formatı."))
		return
	}

	// 4. display_name doğrulama.
	displayName := strings.TrimSpace(req.DisplayName)
	if err := validateDisplayName(displayName); err != nil {
		writeJSON(w, http.StatusBadRequest, errBody(err.Error()))
		return
	}

	// 5. İş mantığını çağır.
	profile, err := h.svc.SyncProfile(r.Context(), userID, displayName)
	if err != nil {
		log.Printf("auth.handleSyncProfile: SyncProfile hatası user_id=%s: %v", userID, err)
		writeJSON(w, http.StatusInternalServerError, errBody("Profil senkronizasyonu başarısız."))
		return
	}

	writeJSON(w, http.StatusOK, profile)
}

// validateDisplayName, display_name için iş kurallarını uygular.
// Hata mesajları doğrudan frontend'e dönebilecek kadar anlaşılırdır.
func validateDisplayName(name string) error {
	if name == "" {
		return errors.New("display_name boş olamaz.")
	}
	if utf8.RuneCountInString(name) > 50 {
		return errors.New("display_name en fazla 50 karakter olabilir.")
	}
	return nil
}

// ── yardımcılar ──────────────────────────────────────────────────────────────

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(v); err != nil {
		log.Printf("auth.writeJSON: encode hatası: %v", err)
	}
}

func errBody(msg string) map[string]string {
	return map[string]string{"error": msg}
}
