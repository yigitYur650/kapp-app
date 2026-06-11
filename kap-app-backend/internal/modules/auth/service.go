package auth

import (
	"context"
	"fmt"
	"log"

	"assignment-backend/pkg/utils"
)

// UserProfile, auth modülünün profil modelidir.
// JSON tag'leri frontend ile sözleşmeyi oluşturur.
type UserProfile struct {
	UserID      string `json:"user_id"`
	SlugID      string `json:"slug_id"`
	DisplayName string `json:"display_name"`
	IsNew       bool   `json:"is_new"` // true → bu çağrıda yeni oluşturuldu
}

// Service, auth modülünün iş mantığı katmanıdır.
type Service struct {
	repo *Repository
}

// NewService, Service örneği oluşturur.
func NewService(repo *Repository) *Service {
	return &Service{repo: repo}
}

// SyncProfile, Supabase Auth'tan gelen userID + display_name için:
//  1. profiles tablosunda kayıt var mı kontrol eder.
//  2. Varsa mevcut profili döner (display_name güncellenmez — idempotent).
//  3. Yoksa benzersiz slug_id üretip kaydeder (max maxRetries deneme).
func (s *Service) SyncProfile(ctx context.Context, userID, displayName string) (*UserProfile, error) {
	const maxRetries = 5

	// 1. Var olan profili getir.
	existing, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("auth.Service.SyncProfile: FindByUserID: %w", err)
	}
	if existing != nil {
		return existing, nil
	}

	// 2. Yeni profil: benzersiz slug_id üret, çakışırsa yeniden dene.
	for attempt := 1; attempt <= maxRetries; attempt++ {
		slug, err := utils.GenerateSlugID()
		if err != nil {
			return nil, fmt.Errorf("auth.Service.SyncProfile: GenerateSlugID (deneme %d): %w", attempt, err)
		}

		profile, err := s.repo.Create(ctx, userID, slug, displayName)
		if err == nil {
			log.Printf(
				"auth.Service.SyncProfile: yeni profil oluşturuldu user_id=%s slug=%s display_name=%q",
				userID, slug, displayName,
			)
			return profile, nil
		}

		if isUniqueViolation(err) {
			log.Printf(
				"auth.Service.SyncProfile: slug çakışması, yeniden deneniyor (%d/%d): %v",
				attempt, maxRetries, err,
			)
			continue
		}

		// Farklı bir DB hatası → sarmala ve döndür.
		return nil, fmt.Errorf("auth.Service.SyncProfile: Create (deneme %d): %w", attempt, err)
	}

	return nil, fmt.Errorf("auth.Service.SyncProfile: %d denemede benzersiz slug üretilemedi", maxRetries)
}
