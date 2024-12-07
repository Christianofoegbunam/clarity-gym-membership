;; Define constants
(define-constant contract-owner tx-sender)
(define-constant membership-duration u2592000) ;; 30 days in seconds
(define-constant err-owner-only (err u100))
(define-constant err-already-member (err u101))
(define-constant err-not-member (err u102))
(define-constant err-insufficient-payment (err u103))
(define-constant membership-fee u100000000) ;; in microSTX

;; Define data vars
(define-map memberships
    principal
    {
        expiry: uint,
        active: bool
    }
)

;; Public functions
(define-public (register-membership)
    (let (
        (current-time (unwrap-panic (get-block-info? time u0)))
        (sender tx-sender)
    )
    (if (is-some (map-get? memberships sender))
        err-already-member
        (begin
            (try! (stx-transfer? membership-fee sender contract-owner))
            (ok (map-set memberships
                sender
                {
                    expiry: (+ current-time membership-duration),
                    active: true
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
    (try! (stx-transfer? membership-fee sender contract-owner))
    (ok (map-set memberships
        sender
        {
            expiry: (+ current-time membership-duration),
            active: true
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

(define-read-only (get-membership-expiry (member principal))
    (let (
        (member-data (map-get? memberships member))
    )
    (if (is-none member-data)
        (ok u0)
        (ok (get expiry (unwrap-panic member-data)))
    ))
)

(define-read-only (get-membership-fee)
    (ok membership-fee)
)
