;; Volunteer Mobilization Contract
;; Rapid mobilization of trained community volunteers

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INVALID_DATA (err u400))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_NOT_AVAILABLE (err u402))
(define-constant ERR_DEPLOYMENT_FAILED (err u403))
(define-constant ERR_INSUFFICIENT_SKILLS (err u405))
(define-constant ERR_EXPIRED_CERTIFICATION (err u406))

;; Volunteer skill types
(define-constant SKILL_MEDICAL_RESPONSE u1)
(define-constant SKILL_SEARCH_RESCUE u2)
(define-constant SKILL_LOGISTICS u3)
(define-constant SKILL_COMMUNICATION u4)
(define-constant SKILL_TECHNICAL u5)
(define-constant SKILL_COORDINATION u6)

;; Deployment status
(define-constant STATUS_AVAILABLE u1)
(define-constant STATUS_DEPLOYED u2)
(define-constant STATUS_ON_MISSION u3)
(define-constant STATUS_RECOVERY u4)
(define-constant STATUS_UNAVAILABLE u5)

;; Emergency priority levels
(define-constant PRIORITY_LOW u1)
(define-constant PRIORITY_MEDIUM u2)
(define-constant PRIORITY_HIGH u3)
(define-constant PRIORITY_CRITICAL u4)
(define-constant PRIORITY_IMMEDIATE u5)

;; Certification levels
(define-constant CERT_BASIC u1)
(define-constant CERT_INTERMEDIATE u2)
(define-constant CERT_ADVANCED u3)
(define-constant CERT_EXPERT u4)

;; Data Variables
(define-data-var next-volunteer-id uint u1)
(define-data-var next-deployment-id uint u1)
(define-data-var next-alert-id uint u1)
(define-data-var next-training-id uint u1)
(define-data-var contract-active bool true)
(define-data-var total-volunteers uint u0)
(define-data-var active-deployments uint u0)

;; Data Structures

;; Volunteer Profiles
(define-map volunteers
  { volunteer-id: uint }
  {
    volunteer-principal: principal,
    name: (string-ascii 100),
    contact-info: (string-ascii 200),
    emergency-contact: (string-ascii 200),
    location: (string-ascii 200),
    coordinates: { lat: int, lng: int },
    skills: (list 10 uint),
    certifications: (list 5 { skill: uint, level: uint, expiry: uint, issuer: (string-ascii 100) }),
    availability-status: uint,
    max-deployment-distance: uint,
    preferred-roles: (list 5 (string-ascii 100)),
    languages: (list 5 (string-ascii 50)),
    equipment-owned: (list 10 (string-ascii 100)),
    experience-years: uint,
    last-active: uint,
    total-deployments: uint,
    performance-rating: uint,
    is-verified: bool
  }
)

;; Volunteer Deployments
(define-map deployments
  { deployment-id: uint }
  {
    volunteer-id: uint,
    emergency-id: uint,
    deployed-by: principal,
    deployment-time: uint,
    expected-duration: uint,
    actual-end-time: (optional uint),
    role-assigned: (string-ascii 100),
    location: (string-ascii 200),
    coordinates: { lat: int, lng: int },
    status: uint,
    priority-level: uint,
    equipment-needed: (list 5 (string-ascii 100)),
    team-assignment: (optional uint),
    supervisor: (optional principal),
    safety-briefing: bool,
    check-in-frequency: uint,
    last-check-in: uint,
    mission-notes: (string-ascii 500)
  }
)

;; Emergency Alerts
(define-map emergency-alerts
  { alert-id: uint }
  {
    emergency-id: uint,
    alert-time: uint,
    alert-type: (string-ascii 50),
    severity: uint,
    skills-needed: (list 10 uint),
    volunteers-needed: uint,
    location: (string-ascii 200),
    response-deadline: uint,
    special-requirements: (string-ascii 300),
    deployment-duration: uint,
    compensation: (optional uint),
    contact-person: principal,
    status: (string-ascii 20)
  }
)

;; Training Records
(define-map training-records
  { training-id: uint }
  {
    volunteer-id: uint,
    training-type: (string-ascii 100),
    completion-date: uint,
    instructor: (string-ascii 100),
    certification-earned: (optional uint),
    score: uint,
    valid-until: uint,
    renewal-required: bool,
    training-hours: uint,
    competencies: (list 5 (string-ascii 100))
  }
)

;; Team Assignments
(define-map teams
  { team-id: uint }
  {
    team-name: (string-ascii 100),
    team-leader: uint,
    members: (list 20 uint),
    specialization: (string-ascii 100),
    formation-date: uint,
    active-mission: (optional uint),
    team-status: (string-ascii 20),
    performance-history: uint,
    training-level: uint
  }
)

;; Alert Responses
(define-map alert-responses
  { alert-id: uint, volunteer-id: uint }
  {
    response-time: uint,
    availability: bool,
    estimated-arrival: uint,
    special-notes: (string-ascii 200),
    equipment-available: (list 5 (string-ascii 100)),
    team-preference: (optional uint)
  }
)

;; Performance Tracking
(define-map performance-records
  { volunteer-id: uint, deployment-id: uint }
  {
    punctuality-score: uint,
    skill-demonstration: uint,
    teamwork-rating: uint,
    safety-compliance: uint,
    communication-quality: uint,
    overall-performance: uint,
    supervisor-feedback: (string-ascii 300),
    areas-for-improvement: (string-ascii 300),
    recognition-earned: (optional (string-ascii 100))
  }
)

;; Lookup Maps
(define-map volunteer-by-principal { principal: principal } { volunteer-id: uint })
(define-map volunteers-by-skill { skill: uint } { volunteer-count: uint })
(define-map active-alerts { emergency-id: uint } { alert-id: uint })

;; Read-only Functions

(define-read-only (get-volunteer (volunteer-id uint))
  (map-get? volunteers { volunteer-id: volunteer-id })
)

(define-read-only (get-deployment (deployment-id uint))
  (map-get? deployments { deployment-id: deployment-id })
)

(define-read-only (get-emergency-alert (alert-id uint))
  (map-get? emergency-alerts { alert-id: alert-id })
)

(define-read-only (get-volunteer-by-principal (user principal))
  (match (map-get? volunteer-by-principal { principal: user })
    volunteer-record (get-volunteer (get volunteer-id volunteer-record))
    none
  )
)

(define-read-only (count-available-volunteers (skill uint) (location (string-ascii 200)))
  ;; Count volunteers with specific skill available near location
  (default-to u0 (get volunteer-count (map-get? volunteers-by-skill { skill: skill })))
)

(define-read-only (calculate-response-time (volunteer-id uint) (emergency-location (string-ascii 200)))
  ;; Calculate estimated response time for volunteer to reach emergency
  u1800 ;; Placeholder: 30 minutes
)

(define-read-only (check-certification-validity (volunteer-id uint) (skill uint))
  ;; Check if volunteer's certification for skill is still valid
  (match (get-volunteer volunteer-id)
    volunteer-data true ;; Simplified validation
    false
  )
)

(define-read-only (get-volunteer-performance (volunteer-id uint))
  (match (get-volunteer volunteer-id)
    volunteer-data (get performance-rating volunteer-data)
    u0
  )
)

(define-read-only (get-total-volunteers)
  (var-get total-volunteers)
)

(define-read-only (get-active-deployments)
  (var-get active-deployments)
)

;; Public Functions

;; Register as volunteer
(define-public (register-volunteer
  (name (string-ascii 100))
  (contact-info (string-ascii 200))
  (emergency-contact (string-ascii 200))
  (location (string-ascii 200))
  (coordinates { lat: int, lng: int })
  (skills (list 10 uint))
  (certifications (list 5 { skill: uint, level: uint, expiry: uint, issuer: (string-ascii 100) }))
  (max-deployment-distance uint)
  (preferred-roles (list 5 (string-ascii 100)))
  (languages (list 5 (string-ascii 50)))
  (equipment-owned (list 10 (string-ascii 100)))
  (experience-years uint))
  
  (let ((volunteer-id (var-get next-volunteer-id)))
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (is-none (map-get? volunteer-by-principal { principal: tx-sender })) ERR_ALREADY_EXISTS)
    (asserts! (> (len skills) u0) ERR_INVALID_DATA)
    
    (map-set volunteers
      { volunteer-id: volunteer-id }
      {
        volunteer-principal: tx-sender,
        name: name,
        contact-info: contact-info,
        emergency-contact: emergency-contact,
        location: location,
        coordinates: coordinates,
        skills: skills,
        certifications: certifications,
        availability-status: STATUS_AVAILABLE,
        max-deployment-distance: max-deployment-distance,
        preferred-roles: preferred-roles,
        languages: languages,
        equipment-owned: equipment-owned,
        experience-years: experience-years,
        last-active: block-height,
        total-deployments: u0,
        performance-rating: u5, ;; Starting rating
        is-verified: false
      }
    )
    
    ;; Update skill counts
    (fold update-skill-count-fold skills u0)
    
    (map-set volunteer-by-principal { principal: tx-sender } { volunteer-id: volunteer-id })
    (var-set next-volunteer-id (+ volunteer-id u1))
    (var-set total-volunteers (+ (var-get total-volunteers) u1))
    (ok volunteer-id)
  )
)

;; Update volunteer availability
(define-public (update-availability (new-status uint))
  (let ((volunteer-data (unwrap! (get-volunteer-by-principal tx-sender) ERR_NOT_FOUND)))
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (<= new-status STATUS_UNAVAILABLE) ERR_INVALID_DATA)
    
    (match (map-get? volunteer-by-principal { principal: tx-sender })
      volunteer-record
        (let ((volunteer-id (get volunteer-id volunteer-record)))
          (map-set volunteers
            { volunteer-id: volunteer-id }
            (merge volunteer-data {
              availability-status: new-status,
              last-active: block-height
            })
          )
          (ok true)
        )
      ERR_NOT_FOUND
    )
  )
)

;; Send emergency alert to volunteers
(define-public (send-emergency-alert
  (emergency-id uint)
  (alert-type (string-ascii 50))
  (severity uint)
  (skills-needed (list 10 uint))
  (volunteers-needed uint)
  (location (string-ascii 200))
  (response-deadline uint)
  (special-requirements (string-ascii 300))
  (deployment-duration uint)
  (compensation (optional uint)))
  
  (let ((alert-id (var-get next-alert-id)))
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (<= severity PRIORITY_IMMEDIATE) ERR_INVALID_DATA)
    (asserts! (> volunteers-needed u0) ERR_INVALID_DATA)
    (asserts! (> response-deadline block-height) ERR_INVALID_DATA)
    
    (map-set emergency-alerts
      { alert-id: alert-id }
      {
        emergency-id: emergency-id,
        alert-time: block-height,
        alert-type: alert-type,
        severity: severity,
        skills-needed: skills-needed,
        volunteers-needed: volunteers-needed,
        location: location,
        response-deadline: response-deadline,
        special-requirements: special-requirements,
        deployment-duration: deployment-duration,
        compensation: compensation,
        contact-person: tx-sender,
        status: "active"
      }
    )
    
    (map-set active-alerts { emergency-id: emergency-id } { alert-id: alert-id })
    (var-set next-alert-id (+ alert-id u1))
    (ok alert-id)
  )
)

;; Respond to emergency alert
(define-public (respond-to-alert
  (alert-id uint)
  (availability bool)
  (estimated-arrival uint)
  (special-notes (string-ascii 200))
  (equipment-available (list 5 (string-ascii 100)))
  (team-preference (optional uint)))
  
  (let (
    (alert-data (unwrap! (get-emergency-alert alert-id) ERR_NOT_FOUND))
    (volunteer-record (unwrap! (map-get? volunteer-by-principal { principal: tx-sender }) ERR_NOT_FOUND))
    (volunteer-id (get volunteer-id volunteer-record))
  )
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status alert-data) "active") ERR_INVALID_DATA)
    (asserts! (> (get response-deadline alert-data) block-height) ERR_INVALID_DATA)
    
    (map-set alert-responses
      { alert-id: alert-id, volunteer-id: volunteer-id }
      {
        response-time: block-height,
        availability: availability,
        estimated-arrival: estimated-arrival,
        special-notes: special-notes,
        equipment-available: equipment-available,
        team-preference: team-preference
      }
    )
    (ok true)
  )
)

;; Deploy volunteer to emergency
(define-public (deploy-volunteer
  (volunteer-id uint)
  (emergency-id uint)
  (role-assigned (string-ascii 100))
  (location (string-ascii 200))
  (coordinates { lat: int, lng: int })
  (priority-level uint)
  (expected-duration uint)
  (equipment-needed (list 5 (string-ascii 100)))
  (team-assignment (optional uint))
  (supervisor (optional principal))
  (check-in-frequency uint))
  
  (let (
    (deployment-id (var-get next-deployment-id))
    (volunteer-data (unwrap! (get-volunteer volunteer-id) ERR_NOT_FOUND))
  )
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get availability-status volunteer-data) STATUS_AVAILABLE) ERR_NOT_AVAILABLE)
    (asserts! (<= priority-level PRIORITY_IMMEDIATE) ERR_INVALID_DATA)
    
    (map-set deployments
      { deployment-id: deployment-id }
      {
        volunteer-id: volunteer-id,
        emergency-id: emergency-id,
        deployed-by: tx-sender,
        deployment-time: block-height,
        expected-duration: expected-duration,
        actual-end-time: none,
        role-assigned: role-assigned,
        location: location,
        coordinates: coordinates,
        status: STATUS_DEPLOYED,
        priority-level: priority-level,
        equipment-needed: equipment-needed,
        team-assignment: team-assignment,
        supervisor: supervisor,
        safety-briefing: false,
        check-in-frequency: check-in-frequency,
        last-check-in: block-height,
        mission-notes: ""
      }
    )
    
    ;; Update volunteer status
    (map-set volunteers
      { volunteer-id: volunteer-id }
      (merge volunteer-data {
        availability-status: STATUS_DEPLOYED,
        last-active: block-height,
        total-deployments: (+ (get total-deployments volunteer-data) u1)
      })
    )
    
    (var-set next-deployment-id (+ deployment-id u1))
    (var-set active-deployments (+ (var-get active-deployments) u1))
    (ok deployment-id)
  )
)

;; Update deployment status
(define-public (update-deployment-status
  (deployment-id uint)
  (new-status uint)
  (mission-notes (string-ascii 500)))
  
  (let (
    (deployment-data (unwrap! (get-deployment deployment-id) ERR_NOT_FOUND))
    (volunteer-data (unwrap! (get-volunteer (get volunteer-id deployment-data)) ERR_NOT_FOUND))
  )
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (or
      (is-eq tx-sender (get volunteer-principal volunteer-data))
      (is-eq tx-sender (get deployed-by deployment-data))
      (is-some (get supervisor deployment-data))
    ) ERR_NOT_AUTHORIZED)
    
    (map-set deployments
      { deployment-id: deployment-id }
      (merge deployment-data {
        status: new-status,
        last-check-in: block-height,
        mission-notes: mission-notes
      })
    )
    (ok true)
  )
)

;; Complete deployment
(define-public (complete-deployment (deployment-id uint))
  (let (
    (deployment-data (unwrap! (get-deployment deployment-id) ERR_NOT_FOUND))
    (volunteer-data (unwrap! (get-volunteer (get volunteer-id deployment-data)) ERR_NOT_FOUND))
  )
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (not (is-eq (get status deployment-data) STATUS_RECOVERY)) ERR_INVALID_DATA)
    
    (map-set deployments
      { deployment-id: deployment-id }
      (merge deployment-data {
        status: STATUS_RECOVERY,
        actual-end-time: (some block-height)
      })
    )
    
    ;; Update volunteer availability
    (map-set volunteers
      { volunteer-id: (get volunteer-id deployment-data) }
      (merge volunteer-data {
        availability-status: STATUS_AVAILABLE,
        last-active: block-height
      })
    )
    
    (var-set active-deployments (- (var-get active-deployments) u1))
    (ok true)
  )
)

;; Helper function to update skill counts
(define-private (update-skill-count (skill uint))
  (map-set volunteers-by-skill
    { skill: skill }
    { volunteer-count: (+ u1 (default-to u0 
      (get volunteer-count (map-get? volunteers-by-skill { skill: skill })))) }
  )
)

;; Fold-compatible version for updating skill counts
(define-private (update-skill-count-fold (skill uint) (acc uint))
  (begin
    (update-skill-count skill)
    acc
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


;; title: volunteer-mobilization
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

