;run with CHICKEN Scheme!
(import (chicken condition)) ;exceptional chicken
(import srfi-1) ;filter
(import srfi-13) ;string support in Scheme
(import srfi-69) ;hashtable support in Scheme
(import amb)     ;amb to implement superpose nesting behavior
(import amb-extras) ;amb1 to implement superpose
(import matchable) ;let/case constructs with list deconstruction
(import (chicken string)) ;->string function to convert scheme expressions to string
(import bindings) ;bind-case with deconstruction
(import match-generics) ;a proper define for scheme

(define (print-all xs)
  (display "[")
  (define (print-items xs)
    (cond
      ((null? xs)
       (display "]")
       (newline))
      (else
       (display (car xs))
       (if (not (null? (cdr xs)))
           (display ", "))
       (print-items (cdr xs)))))
  (print-items xs))

(define (notUnspecified x)
        (not (== x (if #f 42))))

(define-syntax collapse
  (syntax-rules ()
    ((_ args)
     (filter notUnspecified (amb-collect (handle-exceptions exn ((amb-failure-continuation)) args))))))

(define-syntax superpose
  (syntax-rules ()
    ((_ args)
     (amb1 (superpose-helper args)))))

(define-syntax superpose-helper
  (syntax-rules ()
    ((_ (list (superpose x) ...))
     (amb x ...))
    ((_ arg)
     arg)))

(define functions (make-hash-table))

(define-syntax define-partial
  (syntax-rules ()
    ((_ (name xi ...) body)
     (begin (define-dx (name xi ...) (if (and (or (not (equal? 'xi 'Nil)) (equal? xi '())) ...)
                                      (handle-exceptions exn ((amb-failure-continuation)) body)
                                      ((amb-failure-continuation))))
            (if (hash-table-exists? functions 'name)
                (hash-table-set! functions 'name (cons name (hash-table-ref functions 'name)))
                (hash-table-set! functions 'name (list name)))
            (define (name xi ...) ((amb1 (hash-table-ref functions 'name)) xi ...))))))

(define-syntax =
  (syntax-rules () ;hard to generalize further but sufficiently powerful already
    ((_ (name (args1 ...)) body) ;deconstruct 1 list argument
     (begin (define-partial (name $T1)
                            (match-let* (((args1 ...) $T1)) body))))
    ((_ (name (args1 ...) (args2 ...)) body) ;deconstruct 2 list arguments
     (begin (define-partial (name $T1 $T2)
                            (match-let* ((((args1 ...) (args2 ...)) (list $T1 $T2))) body))))
    ((_ (name (args1 ...) (args2 ...) (args3 ...)) body) ;deconstruct 3 list arguments
     (begin (define-partial (name $T1 $T2 $T3)
                            (match-let* ((((args1 ...) (args2 ...) (args3 ...)) (list $T1 $T2 $T3))) body))))
    ((_ (name (args1 ...) xi ...) body) ;deconstruct 1 list argument with params
     (begin (define-partial (name $T1 xi ...)
                            (match-let* (((args1 ...) $T1)) body))))
    ((_ (name (args1 ...) (args2 ...) xi ...) body) ;deconstruct 2 list arguments with params
     (begin (define-partial (name $T1 $T2 xi ...)
                            (match-let* ((((args1 ...) (args2 ...)) (list $T1 $T2))) body))))
    ((_ (name (args1 ...) (args2 ...) (args3 ...) xi ...) body) ;deconstruct 3 list arguments with params
     (begin (define-partial (name $T1 $T2 $T3 xi ...)
                            (match-let* ((((args1 ...) (args2 ...) (args3 ...)) (list $T1 $T2 $T3))) body))))
    ((_ (name xi ...) body) ;normal function definition with flattened params
     (define-partial (name xi ...) body))))

(define-syntax !
  (syntax-rules ()
    ((_ args ...)
     (print-all (amb-collect args ...)))))

(define-syntax LetMetta
  (syntax-rules ()
    ((_ varval body)
     (match-let* varval body))
    ((_ var val body)
     (match-let* ((var val)) body))))

(define-syntax Let*Metta
  (syntax-rules ()
    ((_ ((vari vali) ...) body)
     (match-let* ((vari vali) ...) body)) 
    ((_ (((vari1 vari2) vali) ...) body)
     (match-let* (((vari1 vari2) vali) ...) body))))

(define-syntax CaseMetta
  (syntax-rules (else)
    ((_ var ((pat body) ...))
     (handle-exceptions exn ((amb-failure-continuation)) (bind-case var (pat body) ...)))))

(define &self '())

(define-syntax add-atom
  (syntax-rules ()
    ((_ space (atomi ...))
     (set! space (cons (list atomi ...) space)))))

(define == equal?) ;allow use == for MeTTa compatibility

(define-syntax sequential ;sequential cannot be superpose in Scheme as in MeTTa
  (syntax-rules ()        ;as procedural sequential execution demands :begin"
    ((_ (expr ...))       ;that's why this construct is defined here instead
     (begin
       expr ...))))

(define-syntax If
  (syntax-rules ()
    ((_ condition thenbody elsebody)
        (if condition thenbody elsebody))
    ((_ condition thenbody)
        (if condition thenbody '()))))

(define-syntax MatchMetta
  (syntax-rules ()
    ((_ space binds result)
     (match-let* ((binds (amb1 space))) result))))
