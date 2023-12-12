#lang racket

(require racket/string)

(struct range (from size))

(struct range-mapping (to from size))

(define (compare-range-by-from r1 r2)
  (< (range-mapping-from r1) (range-mapping-from r2)))

(define (display-range r)
  (printf "Range: [~a,~a) (+~a)\n"
          (range-from r)
          (+ (range-from r) (range-size r))
          (range-size r)))

(define (display-range-mapping r)
  (printf "Range: ~a <= [~a,~a) (+~a)\n"
          (range-mapping-to r)
          (range-mapping-from r)
          (+ (range-mapping-from r) (range-mapping-size r))
          (range-mapping-size r)))

(define (parse-range line)
  (apply range-mapping (map string->number (string-split line " "))))

;; https://codereview.stackexchange.com/questions/87058/splitting-a-list-in-racket
;; with evq? changed to equal?
(define (split-by lst x)
  (foldr (lambda (element next)
           (if (equal? element x)
             (cons empty next)
             (cons (cons element (first next)) (rest next))))
         (list empty) lst))

(define (not-ending-with-map? str)
  (not (string-suffix? str "map:")))

(define (parse-and-sort-map map-lines)
  (sort (map parse-range map-lines) compare-range-by-from))

(define (convert-range seed-range sorted-range-mappings)
  (if (empty? sorted-range-mappings)
      (list seed-range)
      (match-let ([(struct range (from size)) seed-range]
                  [(struct range-mapping (m-to m-from m-size)) (first sorted-range-mappings)])
        (cond
          ; seed-range upper bound is smaller than range-mapping-from; no mapping for it
          [(<= (+ from size) m-from)
            (list seed-range)]

          ; seed-range-from < range-mapping-from < seed-range upper
          [(< from m-from)
            (let ([unmapped-size (- m-from from)])
              (cons
                (range from unmapped-size)
                ; split and recur with current mapping
                (convert-range (range m-from (- size unmapped-size)) sorted-range-mappings)))]

          ; seed-range-from < range-mapping upper
          [(< from (+ m-from m-size))
            (let ([offset (- from m-from)]
                  [seed-upper (+ from size)]
                  [m-upper (+ m-from m-size)])
              (if (<= seed-upper m-upper)
                ; fully mapped
                (list (range (+ m-to offset) size))
                ; partially mapped and recur to next mapping
                (cons
                  (range (+ m-to offset) (- m-size offset))
                  (convert-range (range m-upper (- seed-upper m-upper)) (rest sorted-range-mappings)))))]

          ; no interesction with the current mapping, recur to next
          [else (convert-range seed-range (rest sorted-range-mappings))]))))

(define (convert-ranges sorted-range-mappings seed-ranges)
  (flatten (map (lambda (r) (convert-range r sorted-range-mappings)) seed-ranges)))

(define all-lines (string-split (port->string (current-input-port)) "\n"))

(define seeds-line (list-ref (string-split (car all-lines) ":") 1))

(define range-maps-lines
  (split-by (filter not-ending-with-map? (drop all-lines 2)) ""))

(define all-range-maps (map parse-and-sort-map range-maps-lines))

(define seeds (map string->number (string-split seeds-line " ")))

(define (partition lst n)
   (if (empty? lst)
       '()
       (cons (take lst n) (partition (drop lst n) n))))

(define seed-ranges (map (lambda (pair) (apply range pair)) (partition seeds 2)))

(define (convert-through ranges)
  (foldl convert-ranges ranges all-range-maps))

(displayln (apply min (map range-from (convert-through seed-ranges))))
