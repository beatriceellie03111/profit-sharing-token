
;; title: profit-calculator
;; version: 1.0.0
;; summary: Calculates profit percentages on token resales and secondary market activity
;; description: This contract provides functionality to track sales, calculate profits,
;;              and determine distributable amounts for token holders

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_SALE_NOT_FOUND (err u102))
(define-constant MIN_PROFIT_PERCENTAGE u100) ;; 1% minimum
(define-constant MAX_PROFIT_PERCENTAGE u2000) ;; 20% maximum

;; data vars
(define-data-var total-sales-tracked uint u0)
(define-data-var total-profits-calculated uint u0)
(define-data-var profit-percentage uint u500) ;; 5% default

;; data maps
(define-map sales-history
    { sale-id: uint }
    {
        seller: principal,
        buyer: principal,
        original-price: uint,
        sale-price: uint,
        profit-amount: uint,
        timestamp: uint
    }
)

(define-map secondary-sales
    { token-id: uint, sale-number: uint }
    {
        previous-price: uint,
        current-price: uint,
        profit-margin: uint,
        distributable-amount: uint
    }
)

;; public functions

;; Track a secondary sale and calculate profits
(define-public (track-secondary-sale (token-id uint) (sale-number uint) (previous-price uint) (current-price uint) (seller principal) (buyer principal))
    (let (
        (sale-id (+ (var-get total-sales-tracked) u1))
        (profit-amount (if (> current-price previous-price) (- current-price previous-price) u0))
        (distributable-amount (/ (* profit-amount (var-get profit-percentage)) u10000))
    )
        (asserts! (> current-price u0) ERR_INVALID_AMOUNT)
        (asserts! (> previous-price u0) ERR_INVALID_AMOUNT)
        
        ;; Record the sale in sales history
        (map-set sales-history
            { sale-id: sale-id }
            {
                seller: seller,
                buyer: buyer,
                original-price: previous-price,
                sale-price: current-price,
                profit-amount: profit-amount,
                timestamp: stacks-block-height
            }
        )
        
        ;; Record secondary sale details
        (map-set secondary-sales
            { token-id: token-id, sale-number: sale-number }
            {
                previous-price: previous-price,
                current-price: current-price,
                profit-margin: profit-amount,
                distributable-amount: distributable-amount
            }
        )
        
        ;; Update tracking variables
        (var-set total-sales-tracked sale-id)
        (var-set total-profits-calculated (+ (var-get total-profits-calculated) profit-amount))
        
        (ok distributable-amount)
    )
)

;; Calculate profit percentage for a given sale
(define-public (calculate-profit-percentage (original-price uint) (sale-price uint))
    (begin
        (asserts! (> sale-price u0) ERR_INVALID_AMOUNT)
        (asserts! (> original-price u0) ERR_INVALID_AMOUNT)
        
        (if (> sale-price original-price)
            (ok (/ (* (- sale-price original-price) u10000) original-price))
            (ok u0)
        )
    )
)

;; Set profit percentage (only contract owner)
(define-public (set-profit-percentage (new-percentage uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (>= new-percentage MIN_PROFIT_PERCENTAGE) ERR_INVALID_AMOUNT)
        (asserts! (<= new-percentage MAX_PROFIT_PERCENTAGE) ERR_INVALID_AMOUNT)
        
        (var-set profit-percentage new-percentage)
        (ok new-percentage)
    )
)

;; read only functions

;; Get distributable amount for a specific sale
(define-read-only (get-distributable-amount (token-id uint) (sale-number uint))
    (match (map-get? secondary-sales { token-id: token-id, sale-number: sale-number })
        sale-data (ok (get distributable-amount sale-data))
        ERR_SALE_NOT_FOUND
    )
)

;; Get sale details by sale ID
(define-read-only (get-sale-details (sale-id uint))
    (map-get? sales-history { sale-id: sale-id })
)

;; Get secondary sale details
(define-read-only (get-secondary-sale-details (token-id uint) (sale-number uint))
    (map-get? secondary-sales { token-id: token-id, sale-number: sale-number })
)

;; Get current profit percentage
(define-read-only (get-profit-percentage)
    (ok (var-get profit-percentage))
)

;; Get total sales tracked
(define-read-only (get-total-sales)
    (ok (var-get total-sales-tracked))
)

;; Get total profits calculated
(define-read-only (get-total-profits)
    (ok (var-get total-profits-calculated))
)

;; Calculate potential profit for a proposed sale
(define-read-only (calculate-potential-profit (original-price uint) (proposed-price uint))
    (if (> proposed-price original-price)
        (let (
            (profit-amount (- proposed-price original-price))
            (distributable-amount (/ (* profit-amount (var-get profit-percentage)) u10000))
        )
            (ok {
                profit-amount: profit-amount,
                distributable-amount: distributable-amount,
                profit-percentage: (/ (* profit-amount u10000) original-price)
            })
        )
        (ok {
            profit-amount: u0,
            distributable-amount: u0,
            profit-percentage: u0
        })
    )
)

;; private functions

;; Validate sale parameters
(define-private (validate-sale-params (original-price uint) (sale-price uint))
    (and (> original-price u0) (> sale-price u0))
)
