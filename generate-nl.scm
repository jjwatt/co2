#lang racket

(require racket/cmdline)
(require data/gvector)

(define (has-comment? line)
  (and (> (string-length line) 32) (char=? (string-ref line 32) #\;)))

(define (has-label? line)
  (and (> (string-length line) 32)
       (regexp-match #px"^[\\w]+:" (substring line 32))))

(define (get-label line)
  (cadr (regexp-match #px"^([\\w]+):" (substring line 32))))

(define (valid-address? text)
  (let ((c (string-ref text 0)))
    (or (char-alphabetic? c) (char-numeric? c))))

(define (process-listing lines f)
  (let ((count 0)
        (build (make-hash))
        (address #f)
        (label #f)
        (comment #f)
        (keys #f))
    (for ([line lines])
         (set! address #f)
         (set! label #f)
         (set! comment #f)
         (when (has-comment? line)
               (set! address (substring line 1 5))
               (set! comment (substring line 33)))
         (when (has-label? line)
               (set! address (substring line 1 5))
               (set! label (get-label line)))
         (when (and address (valid-address? address))
               (when (not (hash-has-key? build address))
                     (hash-set! build address (vector #f #f)))
               (when label
                     (vector-set! (hash-ref build address) 0 label))
               (when comment
                     (vector-set! (hash-ref build address) 1 comment))))
    ;
    (set! keys (sort (hash-keys build) string<?))
    (for [(k keys)]
         (set! address k)
         (set! label (or (vector-ref (hash-ref build k) 0) ""))
         (set! comment (or (vector-ref (hash-ref build k) 1) ""))
         (write-string (format "$~a#~a#~a" address label comment) f)
         (newline f))))

(define (generate-nl in-name out-name)
  (let ((f (open-output-file out-name #:exists 'replace)))
    (process-listing (file->lines in-name) f)
    (close-output-port f)))

(provide generate-nl)
