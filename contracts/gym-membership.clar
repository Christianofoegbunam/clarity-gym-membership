;; Define constants
(define-constant contract-owner tx-sender)
(define-constant membership-duration u2592000) ;; 30 days in seconds
(define-constant err-owner-only (err u100))
(define-constant err-already-member (err u101))
(define-constant err-not-member (err u102))
(define-constant err-insufficient-payment (err u103))
(define-constant err-invalid-tier (err u104))

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

;; Public functions
(define-public (register-membership (tier uint))
    (let (
        (current-time (unwrap-panic (get-block-info? time u0)))
        (sender tx-sender)
        (fee (get-tier-fee tier))
    )
    (asserts! (> fee u0) err-invalid-tier)
    (if (is-some (map-get? memberships sender))
        err-already-member
        (begin
            (try! (stx-transfer? fee sender contract-owner))
            (ok (map-set memberships
                sender
                {
                    expiry: (+ current-time membership-duration),
                    active: true,
                    tier: tier
                }
            ))
        ))
    )
)

(define-public (renew-membership)
    (let (
        (current-time (unwrap-panic (get-block-info? time u0)))
        (sender tx-sender)
        (member-data (unwrap! (map-get? memberships sender) err-not-member))
        (fee (get-tier-fee (get tier member-data)))
    )
    (try! (stx-transfer? fee sender contract-owner))
    (ok (map-set memberships
        sender
        {
            expiry: (+ current-time membership-duration),
            active: true,
            tier: (get tier member-data)
        }
    ))
    )
)

(define-public (upgrade-tier (new-tier uint))
    (let (
        (sender tx-sender)
        (member-data (unwrap! (map-get? memberships sender) err-not-member))
        (new-fee (get-tier-fee new-tier))
        (current-fee (get-tier-fee (get tier member-data)))
    )
    (asserts! (> new-fee current-fee) err-invalid-tier)
    (try! (stx-transfer? (- new-fee current-fee) sender contract-owner))
    (ok (map-set memberships
        sender
        {
            expiry: (get expiry member-data),
            active: true,
            tier: new-tier
        }
    ))
    )
)

(define-public (cancel-membership (member principal))
    (let (
        (sender tx-sender)
    )
    (asserts! (is-eq sender contract-owner) err-owner-only)
    (ok (map-delete memberships member))
    )
)

;; Read only functions
(define-read-only (get-membership-status (member principal))
    (let (
        (member-data (map-get? memberships member))
    )
    (if (is-none member-data)
        (ok false)
        (let (
            (current-time (unwrap-panic (get-block-info? time u0)))
            (member-info (unwrap-panic member-data))
        )
        (ok (and
            (get active member-info)
            (<= current-time (get expiry member-info))
        ))
        )
    )
)

(define-read-only (get-membership-details (member principal))
    (let (
        (member-data (map-get? memberships member))
    )
    (if (is-none member-data)
        (ok {
            expiry: u0,
            active: false,
            tier: u0
        })
        (ok (unwrap-panic member-data))
    ))
)

(define-read-only (get-tier-fees)
    (ok {
        basic: basic-fee,
        premium: premium-fee,
        elite: elite-fee
    })
)
