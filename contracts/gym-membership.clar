;; Define constants
(define-constant contract-owner tx-sender)
(define-constant membership-duration u2592000) ;; 30 days in seconds
(define-constant err-owner-only (err u100))
(define-constant err-already-member (err u101))
(define-constant err-not-member (err u102))
(define-constant err-insufficient-payment (err u103))
(define-constant err-invalid-tier (err u104))
(define-constant err-expired-membership (err u105))

;; Define membership tiers and fees
(define-constant basic-tier u1)
(define-constant premium-tier u2)
(define-constant elite-tier u3)

(define-constant basic-fee u100000000) ;; in microSTX
(define-constant premium-fee u200000000)
(define-constant elite-fee u300000000)

;; Define data vars
(define-map memberships
    principal
    {
        expiry: uint,
        active: bool,
        tier: uint
    }
)

;; Private functions
(define-private (get-tier-fee (tier uint))
  (match tier
    basic-tier basic-fee
    premium-tier premium-fee
    elite-tier elite-fee
    u0
  )
)

(define-private (is-valid-membership (member-data (optional {expiry: uint, active: bool, tier: uint})))
  (match member-data
    member-info (let ((current-time (unwrap-panic (get-block-info? time u0))))
      (and (get active member-info)
          (>= (get expiry member-info) current-time)))
    false))

;; Added function to validate tier
(define-private (is-valid-tier (tier uint))
  (or (is-eq tier basic-tier)
      (is-eq tier premium-tier)
      (is-eq tier elite-tier)))

;; Public functions
(define-public (register-membership (tier uint))
    (let (
        (current-time (unwrap-panic (get-block-info? time u0)))
        (sender tx-sender)
        (fee (get-tier-fee tier))
    )
    (asserts! (is-valid-tier tier) err-invalid-tier)
    (asserts! (> fee u0) err-invalid-tier)
    (asserts! (is-none (map-get? memberships sender)) err-already-member)
    (try! (stx-transfer? fee sender contract-owner))
    (print {event: "membership-registered", member: sender, tier: tier})
    (ok (map-set memberships
        sender
        {
            expiry: (+ current-time membership-duration),
            active: true,
            tier: tier
        }
    ))
    )
)

;; Added cancellation function
(define-public (cancel-membership (member principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (match (map-get? memberships member)
            member-data (begin
                (print {event: "membership-cancelled", member: member})
                (ok (map-set memberships
                    member
                    {
                        expiry: u0,
                        active: false,
                        tier: (get tier member-data)
                    }
                )))
            err-not-member)
    )
)

;; Enhanced read-only functions
(define-read-only (get-membership-tier (member principal))
    (match (map-get? memberships member)
        member-data (ok (get tier member-data))
        (err err-not-member))
)

[Previous functions remain unchanged...]
