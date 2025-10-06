
;; title: revenue-distributor
;; version: 1.0.0
;; summary: Automated distribution system for sharing profits among token holders
;; description: This contract manages the registration of token holders and distributes
;;              profits proportionally based on their token holdings

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_INVALID_AMOUNT (err u201))
(define-constant ERR_HOLDER_NOT_FOUND (err u202))
(define-constant ERR_INSUFFICIENT_FUNDS (err u203))
(define-constant ERR_ALREADY_CLAIMED (err u204))
(define-constant MIN_DISTRIBUTION_AMOUNT u1000000) ;; 1 STX minimum

;; data vars
(define-data-var total-token-supply uint u1000000) ;; 1M tokens total supply
(define-data-var total-holders uint u0)
(define-data-var current-distribution-round uint u0)
(define-data-var total-distributed uint u0)
(define-data-var contract-balance uint u0)

;; data maps
(define-map token-holders
    { holder: principal }
    {
        token-balance: uint,
        registration-block: uint,
        total-claimed: uint,
        last-claim-round: uint
    }
)

(define-map distribution-rounds
    { round: uint }
    {
        total-amount: uint,
        per-token-amount: uint,
        distribution-block: uint,
        holders-eligible: uint
    }
)

(define-map holder-claims
    { holder: principal, round: uint }
    {
        amount-eligible: uint,
        claimed: bool,
        claim-block: uint
    }
)

;; public functions

;; Register a new token holder or update existing holder's balance
(define-public (register-holder (holder principal) (token-amount uint))
    (let (
        (current-holder (map-get? token-holders { holder: holder }))
    )
        (asserts! (> token-amount u0) ERR_INVALID_AMOUNT)
        
        (match current-holder
            existing-data
            ;; Update existing holder
            (begin
                (map-set token-holders
                    { holder: holder }
                    {
                        token-balance: token-amount,
                        registration-block: (get registration-block existing-data),
                        total-claimed: (get total-claimed existing-data),
                        last-claim-round: (get last-claim-round existing-data)
                    }
                )
                (ok "holder-updated")
            )
            ;; Register new holder
            (begin
                (map-set token-holders
                    { holder: holder }
                    {
                        token-balance: token-amount,
                        registration-block: stacks-block-height,
                        total-claimed: u0,
                        last-claim-round: u0
                    }
                )
                (var-set total-holders (+ (var-get total-holders) u1))
                (ok "holder-registered")
            )
        )
    )
)

;; Distribute profits to all token holders
(define-public (distribute-profits (total-profit uint))
    (let (
        (round (+ (var-get current-distribution-round) u1))
        (per-token-amount (/ total-profit (var-get total-token-supply)))
    )
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (>= total-profit MIN_DISTRIBUTION_AMOUNT) ERR_INVALID_AMOUNT)
        
        ;; Record distribution round
        (map-set distribution-rounds
            { round: round }
            {
                total-amount: total-profit,
                per-token-amount: per-token-amount,
                distribution-block: stacks-block-height,
                holders-eligible: (var-get total-holders)
            }
        )
        
        ;; Update distribution tracking
        (var-set current-distribution-round round)
        (var-set total-distributed (+ (var-get total-distributed) total-profit))
        (var-set contract-balance (+ (var-get contract-balance) total-profit))
        
        (ok round)
    )
)

;; Calculate individual holder's share for a distribution round
(define-public (calculate-share (holder principal) (round uint))
    (let (
        (holder-data (map-get? token-holders { holder: holder }))
        (round-data (map-get? distribution-rounds { round: round }))
    )
        (match holder-data
            holder-info
            (match round-data
                distribution-info
                (let (
                    (holder-tokens (get token-balance holder-info))
                    (per-token-amount (get per-token-amount distribution-info))
                    (share-amount (* holder-tokens per-token-amount))
                )
                    (ok share-amount)
                )
                ERR_INVALID_AMOUNT
            )
            ERR_HOLDER_NOT_FOUND
        )
    )
)

;; Claim profits for a specific distribution round
(define-public (claim-profits (round uint))
    (let (
        (holder tx-sender)
        (claim-key { holder: holder, round: round })
        (existing-claim (map-get? holder-claims claim-key))
    )
        (asserts! (is-none existing-claim) ERR_ALREADY_CLAIMED)
        
        (match (calculate-share holder round)
            share-amount
            (begin
                (asserts! (> share-amount u0) ERR_INVALID_AMOUNT)
                (asserts! (>= (var-get contract-balance) share-amount) ERR_INSUFFICIENT_FUNDS)
                
                ;; Record the claim
                (map-set holder-claims
                    claim-key
                    {
                        amount-eligible: share-amount,
                        claimed: true,
                        claim-block: stacks-block-height
                    }
                )
                
                ;; Update holder's total claimed amount
                (match (map-get? token-holders { holder: holder })
                    holder-data
                    (map-set token-holders
                        { holder: holder }
                        {
                            token-balance: (get token-balance holder-data),
                            registration-block: (get registration-block holder-data),
                            total-claimed: (+ (get total-claimed holder-data) share-amount),
                            last-claim-round: round
                        }
                    )
                    false
                )
                
                ;; Update contract balance
                (var-set contract-balance (- (var-get contract-balance) share-amount))
                
                ;; Transfer the profits (in a real implementation, this would transfer STX)
                (ok share-amount)
            )
            err-value (err err-value)
        )
    )
)

;; Batch distribute to multiple holders (gas-efficient for small groups)
(define-public (batch-distribute (holders (list 10 principal)) (round uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        
        (ok (map process-holder-claim
            (map create-claim-tuple holders)
        ))
    )
)

;; read only functions

;; Get holder information
(define-read-only (get-holder-info (holder principal))
    (map-get? token-holders { holder: holder })
)

;; Get distribution round details
(define-read-only (get-distribution-round (round uint))
    (map-get? distribution-rounds { round: round })
)

;; Get claim status for a holder and round
(define-read-only (get-claim-status (holder principal) (round uint))
    (map-get? holder-claims { holder: holder, round: round })
)

;; Get current distribution round
(define-read-only (get-current-round)
    (ok (var-get current-distribution-round))
)

;; Get total holders count
(define-read-only (get-total-holders)
    (ok (var-get total-holders))
)

;; Get contract statistics
(define-read-only (get-contract-stats)
    (ok {
        total-token-supply: (var-get total-token-supply),
        total-holders: (var-get total-holders),
        current-distribution-round: (var-get current-distribution-round),
        total-distributed: (var-get total-distributed),
        contract-balance: (var-get contract-balance)
    })
)

;; Check if holder is eligible for distribution
(define-read-only (is-holder-eligible (holder principal) (round uint))
    (match (map-get? token-holders { holder: holder })
        holder-data
        (match (map-get? distribution-rounds { round: round })
            round-data
            (ok (<= (get registration-block holder-data) (get distribution-block round-data)))
            (ok false)
        )
        (ok false)
    )
)

;; Get pending distribution rounds for a holder (simplified)
(define-read-only (get-pending-rounds (holder principal))
    (match (map-get? token-holders { holder: holder })
        holder-data
        (ok {
            last-claimed-round: (get last-claim-round holder-data),
            current-round: (var-get current-distribution-round)
        })
        ERR_HOLDER_NOT_FOUND
    )
)

;; private functions

;; Helper function for batch operations
(define-private (create-claim-tuple (holder principal))
    { holder: holder, round: (var-get current-distribution-round) }
)

(define-private (process-holder-claim (claim-data { holder: principal, round: uint }))
    (let (
        (holder (get holder claim-data))
        (round (get round claim-data))
    )
        (calculate-share holder round)
    )
)

;; Validate distribution parameters
(define-private (validate-distribution-params (amount uint) (holders-count uint))
    (and (> amount u0) (> holders-count u0))
)
