package product

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Repository, product modülünün veritabanı erişim katmanıdır.
type Repository struct {
	db *pgxpool.Pool
}

// NewRepository, Repository örneği oluşturur.
func NewRepository(db *pgxpool.Pool) *Repository {
	return &Repository{db: db}
}

// ── Yetki yardımcısı ─────────────────────────────────────────────────────────

// IsTenantMember, userID'nin o evin üyesi olup olmadığını doğrular.
// Tenant modülünden bağımsız kalmak için sorgu burada tekrarlanır.
func (r *Repository) IsTenantMember(ctx context.Context, tenantID, userID string) (bool, error) {
	const q = `
		SELECT 1 FROM tenant_memberships
		WHERE  tenant_id = $1 AND user_id = $2
		LIMIT  1`

	var dummy int
	err := r.db.QueryRow(ctx, q, tenantID, userID).Scan(&dummy)
	if errors.Is(err, pgx.ErrNoRows) {
		return false, nil
	}
	if err != nil {
		return false, fmt.Errorf("product.Repository.IsTenantMember: %w", err)
	}
	return true, nil
}

// ── CRUD işlemleri ────────────────────────────────────────────────────────────

// scanProduct, bir pgx satırını Product yapısına doldurur.
// Tüm nullable alanlar (*float64, *string, *time.Time) pgx tarafından NULL → nil olarak taranır.
func scanProduct(row interface {
	Scan(dest ...any) error
}, p *Product) error {
	return row.Scan(
		&p.ID, &p.TenantID, &p.Name,
		&p.Price, &p.MarketName, &p.Category,
		&p.Quantity, &p.Status, &p.ExpirationDate,
		&p.AddedBy, &p.CreatedAt, &p.UpdatedAt,
	)
}

const selectCols = `
	id, tenant_id, name, price, market_name, category,
	quantity, status, expiration_date, added_by, created_at, updated_at`

// Create, products tablosuna yeni ürün ekler.
func (r *Repository) Create(ctx context.Context, in CreateInput) (*Product, error) {
	q := `
		INSERT INTO products
			(tenant_id, added_by, name, price, market_name, category,
			 quantity, status, expiration_date, created_at, updated_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,'var',$8,NOW(),NOW())
		RETURNING ` + selectCols

	var p Product
	if err := scanProduct(
		r.db.QueryRow(ctx, q,
			in.TenantID, in.AddedBy, in.Name,
			in.Price, in.MarketName, in.Category,
			in.Quantity, in.ExpirationDate,
		),
		&p,
	); err != nil {
		return nil, fmt.Errorf("product.Repository.Create: %w", err)
	}
	return &p, nil
}

// ListByTenantID, bir eve ait ürünleri oluşturulma tarihine göre tersten döner.
func (r *Repository) ListByTenantID(ctx context.Context, tenantID string) ([]Product, error) {
	q := `
		SELECT ` + selectCols + `
		FROM products
		WHERE tenant_id = $1
		ORDER BY created_at DESC`

	rows, err := r.db.Query(ctx, q, tenantID)
	if err != nil {
		return nil, fmt.Errorf("product.Repository.ListByTenantID: %w", err)
	}
	defer rows.Close()

	var list []Product
	for rows.Next() {
		var p Product
		if err := scanProduct(rows, &p); err != nil {
			return nil, fmt.Errorf("product.Repository.ListByTenantID: Scan: %w", err)
		}
		list = append(list, p)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("product.Repository.ListByTenantID: rows.Err: %w", err)
	}

	return list, nil
}

// FindByID, ID ile ürün arar. Bulunamazsa (nil, nil) döner.
func (r *Repository) FindByID(ctx context.Context, productID string) (*Product, error) {
	q := `SELECT ` + selectCols + ` FROM products WHERE id = $1`

	var p Product
	if err := scanProduct(r.db.QueryRow(ctx, q, productID), &p); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("product.Repository.FindByID: %w", err)
	}
	return &p, nil
}

// UpdateStatus, ürünün status ve updated_at alanlarını günceller.
// Ürün bulunamazsa (nil, nil) döner.
func (r *Repository) UpdateStatus(ctx context.Context, productID, status string) (*Product, error) {
	q := `
		UPDATE products
		SET    status = $2, updated_at = NOW()
		WHERE  id = $1
		RETURNING ` + selectCols

	var p Product
	if err := scanProduct(r.db.QueryRow(ctx, q, productID, status), &p); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("product.Repository.UpdateStatus: %w", err)
	}
	return &p, nil
}

// Delete, ürünü veritabanından siler.
// Satır yoksa ErrProductNotFound döner.
func (r *Repository) Delete(ctx context.Context, productID string) error {
	tag, err := r.db.Exec(ctx, `DELETE FROM products WHERE id = $1`, productID)
	if err != nil {
		return fmt.Errorf("product.Repository.Delete: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrProductNotFound
	}
	return nil
}

// CreateInput, Create fonksiyonuna geçilen parametreler.
type CreateInput struct {
	TenantID       string
	AddedBy        string
	Name           string
	Price          *float64
	MarketName     *string
	Category       *string
	Quantity       int
	ExpirationDate *time.Time
}
