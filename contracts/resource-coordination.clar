;; Resource Coordination Contract
;; Real-time coordination of emergency resources

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INVALID_DATA (err u400))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_INSUFFICIENT_RESOURCES (err u402))
(define-constant ERR_EMERGENCY_NOT_ACTIVE (err u403))
(define-constant ERR_ALLOCATION_FAILED (err u405))
(define-constant ERR_DELIVERY_FAILED (err u406))

;; Emergency severity levels
(define-constant SEVERITY_LOW u1)
(define-constant SEVERITY_MODERATE u2)
(define-constant SEVERITY_HIGH u3)
(define-constant SEVERITY_CRITICAL u4)
(define-constant SEVERITY_CATASTROPHIC u5)

;; Resource types
(define-constant RESOURCE_MEDICAL u1)
(define-constant RESOURCE_FOOD_WATER u2)
(define-constant RESOURCE_SHELTER u3)
(define-constant RESOURCE_TRANSPORTATION u4)
(define-constant RESOURCE_COMMUNICATION u5)
(define-constant RESOURCE_PERSONNEL u6)

;; Emergency status
(define-constant STATUS_REPORTED u1)
(define-constant STATUS_ACTIVE u2)
(define-constant STATUS_RESOURCES_DEPLOYED u3)
(define-constant STATUS_RESOLVED u4)
(define-constant STATUS_CLOSED u5)

;; Data Variables
(define-data-var next-emergency-id uint u1)
(define-data-var next-resource-id uint u1)
(define-data-var next-allocation-id uint u1)
(define-data-var next-organization-id uint u1)
(define-data-var contract-active bool true)
(define-data-var total-emergencies uint u0)

;; Data Structures

;; Emergency Incidents
(define-map emergencies
  { emergency-id: uint }
  {
    incident-commander: principal,
    emergency-type: (string-ascii 100),
    severity-level: uint,
    location: (string-ascii 200),
    coordinates: { lat: int, lng: int },
    affected-population: uint,
    reported-time: uint,
    status: uint,
    description: (string-ascii 500),
    required-resources: (list 10 { resource-type: uint, quantity: uint, priority: uint }),
    estimated-duration: uint,
    response-deadline: uint,
    is-active: bool
  }
)

;; Resource Inventory
(define-map resources
  { resource-id: uint }
  {
    owner-org: uint,
    resource-type: uint,
    resource-name: (string-ascii 100),
    quantity-available: uint,
    quantity-allocated: uint,
    location: (string-ascii 200),
    coordinates: { lat: int, lng: int },
    condition: (string-ascii 50),
    expiry-date: (optional uint),
    deployment-time: uint,
    is-available: bool,
    metadata: (string-ascii 300)
  }
)

;; Resource Allocations
(define-map allocations
  { allocation-id: uint }
  {
    emergency-id: uint,
    resource-id: uint,
    quantity-allocated: uint,
    allocated-by: principal,
    allocation-time: uint,
    expected-delivery: uint,
    actual-delivery: (optional uint),
    status: (string-ascii 20),
    delivery-confirmation: bool,
    notes: (string-ascii 300)
  }
)

;; Emergency Response Organizations
(define-map organizations
  { organization-id: uint }
  {
    representative: principal,
    org-name: (string-ascii 200),
    org-type: (string-ascii 50),
    service-areas: (list 5 (string-ascii 100)),
    capabilities: (list 10 (string-ascii 100)),
    contact-info: (string-ascii 300),
    verification-status: (string-ascii 20),
    response-history: uint,
    reliability-score: uint,
    is-active: bool
  }
)

;; Resource Suppliers
(define-map suppliers
  { supplier-id: uint }
  {
    contact: principal,
    supplier-name: (string-ascii 200),
    supply-categories: (list 5 uint),
    service-radius: uint,
    emergency-contact: (string-ascii 100),
    delivery-capability: bool,
    contract-terms: (string-ascii 500),
    verification-level: uint,
    performance-rating: uint
  }
)

;; Emergency Updates
(define-map emergency-updates
  { emergency-id: uint, update-id: uint }
  {
    reporter: principal,
    update-time: uint,
    update-type: (string-ascii 50),
    message: (string-ascii 500),
    severity-change: (optional uint),
    status-change: (optional uint),
    resource-needs: (optional (list 5 { resource-type: uint, quantity: uint }))
  }
)

;; Lookup Maps
(define-map emergency-by-location { location-hash: (buff 32) } { emergency-ids: (list 10 uint) })
(define-map resources-by-type { resource-type: uint } { resource-count: uint })
(define-map org-by-principal { principal: principal } { organization-id: uint })

;; Read-only Functions

(define-read-only (get-emergency (emergency-id uint))
  (map-get? emergencies { emergency-id: emergency-id })
)

(define-read-only (get-resource (resource-id uint))
  (map-get? resources { resource-id: resource-id })
)

(define-read-only (get-allocation (allocation-id uint))
  (map-get? allocations { allocation-id: allocation-id })
)

(define-read-only (get-organization (organization-id uint))
  (map-get? organizations { organization-id: organization-id })
)

(define-read-only (calculate-resource-needs (emergency-id uint))
  (match (get-emergency emergency-id)
    emergency-data
      (let ((severity (get severity-level emergency-data))
            (population (get affected-population emergency-data)))
        (* severity population u10) ;; Simplified calculation
      )
    u0
  )
)

(define-read-only (get-available-resources (resource-type uint) (location (string-ascii 200)))
  ;; Returns count of available resources of specific type near location
  (default-to u0 (get resource-count (map-get? resources-by-type { resource-type: resource-type })))
)

(define-read-only (calculate-response-time (emergency-id uint) (resource-id uint))
  ;; Calculate estimated response time based on distance and resource type
  u3600 ;; Placeholder: 1 hour in seconds
)

(define-read-only (get-next-emergency-id)
  (var-get next-emergency-id)
)

(define-read-only (get-total-emergencies)
  (var-get total-emergencies)
)

;; Public Functions

;; Register emergency response organization
(define-public (register-organization
  (org-name (string-ascii 200))
  (org-type (string-ascii 50))
  (service-areas (list 5 (string-ascii 100)))
  (capabilities (list 10 (string-ascii 100)))
  (contact-info (string-ascii 300)))
  
  (let ((org-id (var-get next-organization-id)))
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (is-none (map-get? org-by-principal { principal: tx-sender })) ERR_ALREADY_EXISTS)
    
    (map-set organizations
      { organization-id: org-id }
      {
        representative: tx-sender,
        org-name: org-name,
        org-type: org-type,
        service-areas: service-areas,
        capabilities: capabilities,
        contact-info: contact-info,
        verification-status: "pending",
        response-history: u0,
        reliability-score: u50,
        is-active: true
      }
    )
    
    (map-set org-by-principal { principal: tx-sender } { organization-id: org-id })
    (var-set next-organization-id (+ org-id u1))
    (ok org-id)
  )
)

;; Report emergency incident
(define-public (report-emergency
  (emergency-type (string-ascii 100))
  (severity-level uint)
  (location (string-ascii 200))
  (coordinates { lat: int, lng: int })
  (affected-population uint)
  (description (string-ascii 500))
  (required-resources (list 10 { resource-type: uint, quantity: uint, priority: uint }))
  (estimated-duration uint))
  
  (let ((emergency-id (var-get next-emergency-id)))
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (<= severity-level SEVERITY_CATASTROPHIC) ERR_INVALID_DATA)
    (asserts! (>= severity-level SEVERITY_LOW) ERR_INVALID_DATA)
    (asserts! (> affected-population u0) ERR_INVALID_DATA)
    
    (map-set emergencies
      { emergency-id: emergency-id }
      {
        incident-commander: tx-sender,
        emergency-type: emergency-type,
        severity-level: severity-level,
        location: location,
        coordinates: coordinates,
        affected-population: affected-population,
        reported-time: block-height,
        status: STATUS_REPORTED,
        description: description,
        required-resources: required-resources,
        estimated-duration: estimated-duration,
        response-deadline: (+ block-height (* estimated-duration u60)), ;; Convert to blocks
        is-active: true
      }
    )
    
    (var-set next-emergency-id (+ emergency-id u1))
    (var-set total-emergencies (+ (var-get total-emergencies) u1))
    (ok emergency-id)
  )
)

;; Register available resources
(define-public (register-resource
  (resource-type uint)
  (resource-name (string-ascii 100))
  (quantity-available uint)
  (location (string-ascii 200))
  (coordinates { lat: int, lng: int })
  (condition (string-ascii 50))
  (expiry-date (optional uint))
  (deployment-time uint)
  (metadata (string-ascii 300)))
  
  (let (
    (resource-id (var-get next-resource-id))
    (org-data (map-get? org-by-principal { principal: tx-sender }))
  )
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (is-some org-data) ERR_NOT_AUTHORIZED)
    (asserts! (> quantity-available u0) ERR_INVALID_DATA)
    (asserts! (<= resource-type RESOURCE_PERSONNEL) ERR_INVALID_DATA)
    
    (map-set resources
      { resource-id: resource-id }
      {
        owner-org: (get organization-id (unwrap-panic org-data)),
        resource-type: resource-type,
        resource-name: resource-name,
        quantity-available: quantity-available,
        quantity-allocated: u0,
        location: location,
        coordinates: coordinates,
        condition: condition,
        expiry-date: expiry-date,
        deployment-time: deployment-time,
        is-available: true,
        metadata: metadata
      }
    )
    
    ;; Update resource type count
    (map-set resources-by-type
      { resource-type: resource-type }
      { resource-count: (+ u1 (default-to u0 
        (get resource-count (map-get? resources-by-type { resource-type: resource-type })))) }
    )
    
    (var-set next-resource-id (+ resource-id u1))
    (ok resource-id)
  )
)

;; Allocate resources to emergency
(define-public (allocate-resource
  (emergency-id uint)
  (resource-id uint)
  (quantity-requested uint)
  (expected-delivery uint)
  (notes (string-ascii 300)))
  
  (let (
    (allocation-id (var-get next-allocation-id))
    (emergency-data (unwrap! (get-emergency emergency-id) ERR_NOT_FOUND))
    (resource-data (unwrap! (get-resource resource-id) ERR_NOT_FOUND))
    (available-quantity (- (get quantity-available resource-data) (get quantity-allocated resource-data)))
  )
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (get is-active emergency-data) ERR_EMERGENCY_NOT_ACTIVE)
    (asserts! (get is-available resource-data) ERR_INSUFFICIENT_RESOURCES)
    (asserts! (<= quantity-requested available-quantity) ERR_INSUFFICIENT_RESOURCES)
    
    ;; Create allocation record
    (map-set allocations
      { allocation-id: allocation-id }
      {
        emergency-id: emergency-id,
        resource-id: resource-id,
        quantity-allocated: quantity-requested,
        allocated-by: tx-sender,
        allocation-time: block-height,
        expected-delivery: expected-delivery,
        actual-delivery: none,
        status: "allocated",
        delivery-confirmation: false,
        notes: notes
      }
    )
    
    ;; Update resource allocation
    (map-set resources
      { resource-id: resource-id }
      (merge resource-data {
        quantity-allocated: (+ (get quantity-allocated resource-data) quantity-requested),
        is-available: (if (>= (+ (get quantity-allocated resource-data) quantity-requested) 
                             (get quantity-available resource-data))
                        false
                        true)
      })
    )
    
    (var-set next-allocation-id (+ allocation-id u1))
    (ok allocation-id)
  )
)

;; Confirm resource delivery
(define-public (confirm-delivery (allocation-id uint))
  (let ((allocation-data (unwrap! (get-allocation allocation-id) ERR_NOT_FOUND)))
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (not (get delivery-confirmation allocation-data)) ERR_INVALID_DATA)
    
    (map-set allocations
      { allocation-id: allocation-id }
      (merge allocation-data {
        actual-delivery: (some block-height),
        status: "delivered",
        delivery-confirmation: true
      })
    )
    (ok true)
  )
)

;; Update emergency status
(define-public (update-emergency-status 
  (emergency-id uint) 
  (new-status uint)
  (update-message (string-ascii 500)))
  
  (let ((emergency-data (unwrap! (get-emergency emergency-id) ERR_NOT_FOUND)))
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq tx-sender (get incident-commander emergency-data)) ERR_NOT_AUTHORIZED)
    (asserts! (<= new-status STATUS_CLOSED) ERR_INVALID_DATA)
    
    (map-set emergencies
      { emergency-id: emergency-id }
      (merge emergency-data { status: new-status })
    )
    (ok true)
  )
)

;; Emergency close
(define-public (close-emergency (emergency-id uint))
  (let ((emergency-data (unwrap! (get-emergency emergency-id) ERR_NOT_FOUND)))
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (or 
      (is-eq tx-sender (get incident-commander emergency-data))
      (is-eq tx-sender CONTRACT_OWNER)
    ) ERR_NOT_AUTHORIZED)
    
    (map-set emergencies
      { emergency-id: emergency-id }
      (merge emergency-data { status: STATUS_CLOSED, is-active: false })
    )
    (ok true)
  )
)

;; Admin functions
(define-public (toggle-contract-active)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (var-set contract-active (not (var-get contract-active)))
    (ok (var-get contract-active))
  )
)


;; title: resource-coordination
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;

;; data vars
;;

;; data maps
;;

;; public functions
;;

;; read only functions
;;

;; private functions
;;

