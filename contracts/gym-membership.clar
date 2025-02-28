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
            (print {event: "membership-registered", member: sender, tier: tier})
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
    )
    (try! (stx-transfer? (get-tier-fee (get tier member-data)) sender contract-owner))
    (print {event: "membership-renewed", member: sender})
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
    (asserts! (is-valid-membership (some member-data)) err-expired-membership)
    (asserts! (> new-fee current-fee) err-invalid-tier)
    (try! (stx-transfer? (- new-fee current-fee) sender contract-owner))
    (print {event: "membership-upgraded", member: sender, new-tier: new-tier})
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

;; Read only functions added/modified
(define-read-only (get-remaining-time (member principal))
    (let (
        (member-data (map-get? memberships member))
        (current-time (unwrap-panic (get-block-info? time u0)))
    )
    (match member-data
        member-info (if (get active member-info)
            (ok (- (get expiry member-info) current-time))
            (ok u0))
        (ok u0))
    )
)

[Previous read-only functions remain unchanged...]
