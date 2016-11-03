;;siebel is proficient in lisp and java
;;C-h w : emacs whereis
;;C-h k : key describe
(defun hello-world ()
  (format t "~&hello, world!"))
;;q key will exit debugger
;;use (load "/home/anoop/pcl/pcl.lisp") to load file on restart
;;or (load (compile-file "/home/anoop/pcl/pcl.lisp"))

;;same as above can be done using C-c C-l or C-c C-k whereby we
;; compile using slime instead of repl

;;slime repl- use , to get command buffer

;;chapter3
(list :a 1 :b 2 :c 3)
(getf (list :a 1 :b 2 :c 3) :c)
(defun make-cd (title artist rating ripped)
  (list :title title
	:artist artist
	:rating rating
	:ripped ripped))
;;(make-cd "Roses" "Kathy Mattea" 7 t)
(defvar *db* nil)
(defun add-record (cd) (push cd *db*))
;;(add-record (make-cd "Roses" "Kathy Mattea" 7 t))
;;(add-record (make-cd "Fly" "Dixie Chicks" 8 t))
;;(add-record (make-cd "Home" "Dixie Chicks" 9 t))
*db*
(defun dump-db ()
  (dolist (cd *db*)
    (format t "~{~A:~10t~A~%~}~%" cd)))
(format *standard-output* "~&t=shorthand for standard-output")
(defun prompt-read (prompt)
  (format *query-io* "~A:** " prompt)
  (force-output *query-io*)
  (read-line *query-io*))
(prompt-read "your name: ")
*query-io*
(defun prompt-for-cd ()
  (make-cd
   (prompt-read "Title")
   (prompt-read "Artist")
   (or (parse-integer (prompt-read "Rating") :junk-allowed t)
       0)
   (y-or-n-p "Ripped [y/n]: ")))
(defun add-cds ()
  (loop (add-record (prompt-for-cd))
     (if (not (y-or-n-p "Another? [y/n]: "))
	 (return))))
(defun load-db (filename)
  (with-open-file (in0 filename)
    (with-standard-io-syntax
      (setf *db* (read in0)))))
(load-db "/home/anoop/pcl/my-cds.db")
(defun save-db (filename)
  (with-open-file (out0 filename
		       :direction :output
		       :if-exists :supersede)
    (with-standard-io-syntax
      (print *db* out0))))
(save-db "/home/anoop/pcl/my-cds.db")
(defun select-by-artist (artist)
  (remove-if-not
   #'(lambda (cd) (equal (getf cd :artist) artist))
   *db*))
(select-by-artist "Kavinsky")
;;generalise above
(defun select (selector-fn)
  (remove-if-not selector-fn *db*))
(select #'(lambda (cd)
	    (equal (getf cd :rating)
		   7)))

;;generate lambda func for select-by-artist in a defun
(defun artist-selector (artist)
  #'(lambda (cd)
      (equal (getf cd :artist) artist)))
(select (artist-selector "Kavinsky"))
;;lets try to generalize above to get lambda func for select

(defun foo (&key a b c)
  (list a b c))
(foo :a 1 :c 3)
(defun foo2 (&key a (b 20) (c 30 c-p0))
  (list a b c c-p0))
(foo2 :a 10)
(foo2 :a 10 :c 30)
;;**-0 means name is given by user eg: c-p0
(defun where (&key title artist rating (ripped nil ripped-p))
  #'(lambda (cd)
      (and (if title (equal (getf cd :title) title) t)
	   (if artist (equal (getf cd :artist) artist) t)
	   (if rating (equal (getf cd :rating) rating) t)
	   (if ripped-p (equal (getf cd :ripped) ripped) t))))
(select (where :rating 7 :artist "Kavinsky"))
(select (where :artist "Kavinsky"))

(defun update (selector-fn
	       &key title artist rating (ripped nil ripped-p))
  (setf *db*
	(mapcar
	 #'(lambda (row)
	     (when (funcall selector-fn row)
	       (if title (setf (getf row :title) title))
	       (if artist (setf (getf row :artist) artist))
	       (if rating (setf (getf row :rating) rating))
	       (if ripped-p (setf (getf row :ripped) ripped)))
	     row) *db*)))
(update (where :artist "Kavinsky" :rating 7) :ripped nil)
(select (where :artist "Kavinsky"))
(update (where :artist "Kavinsky" :rating 7) :ripped t)

(defun delete-rows (selector-fn)
  (setf *db* (remove-if selector-fn *db*)))
(delete-rows (where :artist "Kavinsky"))
(dump-db)
(load-db "/home/anoop/pcl/my-cds.db")
(dump-db)

;;removing code duplication in where & update defun
(defmacro backwards (expr) (reverse expr))
(backwards ("~&hello, macro" t format))
;;macro sends parameters unevaluated

;;error
;;(defun backwards1 (expr) (reverse expr))
;;(backwards1 ("~&hello, function" t format))

;;cumbersome:
(defun make-comparison-expr1 (field value)
  (list 'equal (list 'getf 'cd field) value))
(make-comparison-expr1 'rating 10)

'(1 2 (+ 1 2))
`(1 2 ,(+ 1 2))
(defun make-comparison-expr (field value)
  `(equal (getf cd ,field) ,value))
(make-comparison-expr 'rating 10)
(defun make-comparisons-list (fields)
  (loop while fields
       collecting (make-comparison-expr (pop fields) (pop fields))))
(defmacro where2 (&rest clauses)
  `#'(lambda (cd) (and ,@(make-comparisons-list clauses))))
;;(ppmx (where2 :artist "Kavinsky" :ripped t))
(macroexpand-1 '(where2 :artist "Kavinsky" :ripped t))
(select (where2 :rating 7))

;;chapter4
-8
+8
1/2
(atom nil)
(listp nil)
(format t "~A" "fo\"o")
;; constants are named as +name+
;;never use eq
(eql 1 1.0)
;;chapter5
(defun foo3 (a b &optional (c b c-supplied-p) &rest d)
  (format t "~&~A" d)
  (list a b c c-supplied-p))
(foo3 1 2 2 'these 'go 'in 'rest)
(defun foo5 (n)
  (dotimes (i 10)
    (dotimes (j 10)
      (when (> (* i j) n)
	(return-from foo5 (list i j))))))
(foo5 70)
(funcall #'+ 1 2 3 4)
(defun plot (fn min max step)
  (loop for i from min to max by step do
       (loop repeat (funcall fn i) do (format t "*"))
       (format t "~%")))
(plot #'identity 0 10 1)
(plot #'exp 0 4 .5)
(defparameter *plot-data1* nil)
(setf *plot-data1* `(,#'identity 0 10 1))
(apply #'plot *plot-data1*)
(apply #'plot #'identity 0 '(10 1))
(defun double1 (x)
  (* 2 x))
(apply #'plot #'double1 '(0 10 1))
(apply #'plot #'(lambda (x) (* 2 x)) '(0 10 1))
;;chapter6
;;variables : dynamic , lexical
(dotimes (x 10) (format t "~A" x))
(let ((count 0))
  #'(lambda () (setf count (1+ count))))
;;closure because it closes over the binding created by let

(defvar *count* 0 "count of widgets manufactured")
(defparameter *gap-tolerance* 0.001
  "Tolerance allowed in widgets")
(defun increment-widget-count ()
  (incf *count*))
(increment-widget-count)
(defvar *count* 9)
;;original *count* value not changed in defvar 

*standard-output*

(defun globals-are-dynamic1 (filename)
  (with-open-file (stream0 filename :direction :output
			   :if-exists :supersede)
    (let ((*standard-output* stream0))
      (format t "this will be printed to file: ~A" filename))))
(globals-are-dynamic1 "/home/anoop/pcl/globals-are-dynamic.db")

;;more portable
(defun globals-are-dynamic (pathname)
  (with-open-file (stream0 pathname :direction :output
			   :if-exists :supersede)
    (let ((*standard-output* stream0))
      (format t "this will be printed to file: ~A" pathname))))
(defparameter pathname0 nil)
(setf pathname0 (make-pathname :name "globals-are-dynamic.db"))
(globals-are-dynamic pathname0)
;;notice that after let closes the *standard-output* is reassigned to original value
;;in above let creates a dynamic binding instead of its usual behavior of creating lexical binding because *standard-output* is being a global variable declared as special
(defconstant +e+ 2.72)
(let ((x 1) (y 100))
  (format t "~&x=~A y=~A" x y)
  (rotatef x y)
  (format t "~&x=~A y=~A" x y)
  (shiftf x y 200)
  (format t "~&x=~A y=~A" x y))
;;modify macros are intelligent enough to evaluate parameter only once

;;chapter7
;;macros

;;note: unless is vaguely eql to if-not in english
;;You will be sick if you don't stop eating. 	You'll be sick unless you stop eating.

(when (> 2 1)
  (format t "~&eval this line")
  (format t "~&eval this line too")) 
(defmacro my-when (condition &rest body)
  `(if ,condition
       (progn ,@body)))
(my-when (> 2 1)
  (format t "~&eval this line")
  (format t "~&eval this line too"))

;;unless ~= if (not condition)
(unless (> 1 2)
  (format t "~&eval this")
  (format t "~&eval this too"))
(defmacro my-unless (condition &rest body)
  `(if (not ,condition)
       (progn ,@body)))
(my-unless (> 1 2)
  (format t "~&eval this")
  (format t "~&eval this too"))
(dolist (x (list 'a 'b 'c) 'optional-result)
  (format t "~A" x))
(dotimes (i 10 'return-this)
  (format t "~&~A" i))
;;fibonacci
(do ((n 0 (1+ n))
     (cur 0 next)
     (next 1 (+ cur next)))
    ((= 10 n) 'ended)
  (format t "~&~A:~A" cur next))
;;chapter 8
(fboundp 'foo)
;;below => get me the function stored under symbol foo
#'foo
(defun foo8 (x)
  (when (> x 10) (print 'big)))

;;doprime macro
(defun primep-helper (number)
  "returns list of remainders"
  (when (> number 1)
    (do ((fac 2 (1+ fac))
	 (acc nil))
	((> fac (isqrt number))	(nreverse acc))
      (push (mod number fac) acc))))
;;edge case is giving correct result
(primep-helper 2)
(primep-helper 37)
(defun primep (number)
  (not (member 0 (primep-helper number))))
(primep 37)
(defun next-prime1 (number)
  (do ((i (1+ number) (1+ i)))
      ((primep i) i)
    ()))
;;can omit last () if empty body
(defun next-prime (number)
  (if (zerop number)
      2
      (do ((i (1+ number) (1+ i)))
	  ((primep i) i))))
(next-prime 37)
(next-prime 0)

#|(doprimes (p 0 19)
     (format t "~A " p))|#
(do ((p (next-prime 0) (next-prime p)))
    ((> p 19) 'ended-man)
  (format t "~A " p))
(defmacro doprimes1 (var-and-range &rest body)
  (let ((var (first var-and-range))
	(start (second var-and-range))
	(end (third var-and-range)))
    `(do ((,var (next-prime ,start) (next-prime ,var)))
	 ((> ,var ,end))
       ,@body)))
(doprimes1 (p 0 19)
     (format t "~A " p))
;;macro has auto destructuring
(defmacro doprimes2 ((var start end) &rest body)
    `(do ((,var (next-prime ,start) (next-prime ,var)))
	 ((> ,var ,end))
       ,@body))
(doprimes2 (p 0 19)
	  (format t "~A " p))
(macroexpand-1 '(doprimes (p 0 19)
		 (format t "~A " p)))
;;or use C-c RET

;;fix a leak
(defmacro doprimes3 ((var start end) &rest body)
  `(do ((,var (next-prime ,start) (next-prime ,var))
	(ending-value ,end))
	 ((> ,var ending-value))
       ,@body))
(doprimes3 (p 0 19)
	  (format t "~A " p))
(gensym)

;;fix symbol leak
(defmacro doprimes ((var start end) &rest body)
  (let ((ending-value-name (gensym)))
    `(do ((,var (next-prime ,start) (next-prime ,var))
	  (,ending-value-name ,end))
	 ((> ,var ,ending-value-name))
       ,@body)))
(doprimes (p 0 19)
	  (format t "~A " p))

(defmacro with-gensyms1 (names &body body)
  `(let ,(mapcar #'(lambda (name) `(,name (gensym)))
		 names)
     ,@body))
(defmacro with-gensyms2 ((&rest names) &body body)
  `(let ,(mapcar #'(lambda (name) `(,name (gensym)))
		 names)
     ,@body))

(defmacro doprimes350 ((var start end) &rest body)
  (with-gensyms2 (ending-value-name)
    `(do ((,var (next-prime ,start) (next-prime ,var))
	  (,ending-value-name ,end))
	 ((> ,var ,ending-value-name))
       ,@body)))
(doprimes350 (p 0 19)
	     (format t "~A " p))
(macroexpand-1 '(doprimes350 (p 0 19)
			    (format t "~A " p)))
;;textbook style
(defmacro with-gensyms365 ((&rest names) &body body)
  `(let ,(loop for n in names collect `(,n (gensym)))
     ,@body))
(defmacro doprimes365 ((var start end) &rest body)
  (with-gensyms365 (ending-value-name)
    `(do ((,var (next-prime ,start) (next-prime ,var))
	  (,ending-value-name ,end))
	 ((> ,var ,ending-value-name))
       ,@body)))
(doprimes365 (p 0 19)
	     (format t "~A " p))
(macroexpand-1 '(doprimes365 (p 0 19)
			    (format t "~A " p)))

;;| ;;chapter9
;;| (defun test-+1()
;;|   (and
;;|    (= (+ 1 2) 3)
;;|    (= (+ 1 2 3) 6)
;;|    (= (+ -1 -3) -4)))
;;| (test-+1)
;;| (defun test-+2()
;;|   (format t "~:[FAIL~;pass~] ... ~A~%" (= (+ 1 2) 3)
;;| 	  '(= (+ 1 2) 3))
;;|   (format t "~:[FAIL~;pass~] ... ~A~%" (= (+ 1 2 3) 6)
;;| 	  '(= (+ 1 2 3) 6))
;;|   (format t "~:[FAIL~;pass~] ... ~A~%" (= (+ -1 -3) -4)
;;| 	  '(= (+ -1 -3) -4)))
;;| (test-+2)
;;| (defun report-result (result form)
;;|   (format t "~:[FAIL~;pass~] ... ~A~%" result form)
;;|   result)
;;| (defun test-+33()
;;|   (report-result (= (+ 1 2) 3) '(= (+ 1 2) 3))  
;;|   (report-result (= (+ 1 2 3) 6) '(= (+ 1 2 3) 6))
;;|   (report-result (= (+ -1 -3) -4) '(= (+ -1 -3) -4)))
;;| (test-+33)
;;| (defmacro check1 (form)
;;|   `(report-result ,form ',form))
;;| (defun test-+3()
;;|   (check1 (= (+ 1 2) 3))  
;;|   (check1 (= (+ 1 2 3) 6))
;;|   (check1 (= (+ -1 -3) -4)))
;;| (test-+3)
;;| 
;;| ;;?? how to write this without using eval??
;;| 
;;| ;;;;;;;;;need to debug,
;;| ;;1st round : just copied textbook
;;| (defmacro check3 (&body forms)
;;|   `(combine-results ,@(mapcar #'(lambda (form)
;;| 		 `(report-result (eval ,form)  ',form))
;;| 	     forms)))
;;| 
;;| (check3
;;|   (= (+ 1 2) 3) 
;;|   (= (+ 1 2 3) 6)
;;|   (= (+ -1 -3) 8))
;;| (dtrace report-result)
;;| (defun test-+420 ()
;;|   (check3
;;|     (= (+ 1 2) 3) 
;;|     (= (+ 1 2 3) 6)
;;|     (= (+ -1 -3) -4)))
;;| (test-+420)
;;| ;;;;;;;;;;;;;;;;;;;;;##########
;;| 
;;| 
;;| 
;;| ;;modified with combine-results:
;;| (defmacro check (&body forms)
;;|   `(combine-results
;;|      ,@(mapcar #'(lambda (form)
;;| 		 `,(report-result (eval form) form))
;;| 	     forms)))
;;| (check
;;|   (= (+ 1 2) 3) 
;;|   (= (+ 1 2 3) 6)
;;|   (= (+ -1 -3) -4))
;;| (defun test-+418 ()
;;|   (check
;;|     (= (+ 1 2) 3) 
;;|     (= (+ 1 2 3) 6)
;;|     (= (+ -1 -3) -4)))
;;| (test-+418)
;;| ;;textbook
;;| (defmacro check2 (&body forms)
;;|   `(progn
;;|      ,@(loop for f in forms collect
;;| 	    `(report-result ,f ',f))))
;;| (check2
;;|  (= (+ 1 2) 3) 
;;|  (= (+ 1 2 3) 6)
;;|  (= (+ -1 -3) -4))
;;| 
;;| 
;;| (defun test-+4 ()
;;|   (check2
;;|     (= (+ 1 2) 3) 
;;|     (= (+ 1 2 3) 6)
;;|     (= (+ -1 -3) -4)))
;;| (test-+4)
;;| 
;;| ;;
;;| ;;textbook style
;;| (defmacro combine-results22 (&body forms)
;;|   "textbook copy"
;;|   (with-gensyms2 (result)
;;|     `(let ((,result t))
;;|        ,@(loop for f in forms collect
;;| 	      `(unless ,f (setf ,result nil)))
;;|        ,result)))
;;| 
;;| (defmacro check22 (&body forms)
;;|   "textbook copy with combine-results"
;;|   `(combine-results22
;;|      ,@(loop for f in forms collect
;;| 	    `(report-result22 ,f ',f))))
;;| 
;;| (check22
;;|  (= (+ 1 2) 3) 
;;|  (= (+ 1 2 3) 6)
;;|  (= (+ -1 -3) -4))
;;| 
;;| (defun test-+5 ()
;;|  (let ((*test-name* 'test-+5))
;;|   (check22
;;|     (= (+ 1 2) 3) 
;;|     (= (+ 1 2 3) 6)
;;|     (= (+ -1 -3) -4))))
;;| (test-+5)
;;| 
;;| ;;textbook style ends
;;| (setf forms1 '((= (+ 1 2) 3) 
;;| 	      (= (+ 1 2 3) 6)
;;| 	       (= (+ -1 -3) -4))
;;|       forms2 (copy-list forms1))
;;| #|(combine-results
;;|     (foo)
;;|     (bar)
;;|     (baz))|#
;;| (list (mapcar #'(lambda (x) x) forms1))
;;| (setf result1 t)
;;| (mapcar #'(lambda (x)
;;| 	    (unless (eval x)
;;| 	      (setf result1 nil))) forms1)
;;| (eval (car forms2))
;;| result1
;;| (setf  (car forms2) '(= (+ 1 2) 8))
;;| 
;;| 
;;| (defmacro combine-results (&body forms)
;;|   (with-gensyms2 (result)
;;|     `(let ((,result t))
;;|        ',(mapcar #'(lambda (x)
;;| 		     (unless (eval x)
;;| 		       (setf `,result nil))) forms)
;;|        ,result)))
;;| 
;;| (combine-results (= (+ 1 2) 3)
;;| 		 (= (+ 1 2 3) 6)
;;| 		 (= (+ -1 -3) -4))
;;| 
;;| (defun test-*1 ()
;;|   (let ((*test-name* 'test-*1))
;;|     (check22
;;|       (= (* 2 2) 4)
;;|       (= (* -1 8) -8))))
;;| (test-*1)
;;| (deftest test-*2 ()
;;|     (check22
;;|       (= (* 2 2) 4)
;;|       (= (* -1 8) -8)))
;;| (test-*2)
;;| (defun test-arithmetic ()
;;|   (combine-results22
;;|     (test-+5)
;;|     (test-*1)))
;;| (test-arithmetic)
;;| 
;;| (deftest test-arithmetic22 ()
;;|   (combine-results22
;;|     (test-+6)
;;|     (test-*2)))
;;| (test-arithmetic22)
;;| ;;note to do:
;;| ;; my style prints when I C-xe the defun instead
;;| ;; of when fun is called, fix this bug 2nd round?
;;| (defvar *test-name* nil)
;;| (defun report-result22 (result form)
;;|   "textbook style"
;;|   (format t "~:[FAIL~;pass~] ...~A: ~A~%"
;;| 	  result *test-name* form)
;;|   result)
;;| 
;;| ;;my-deftest emerges
;;| (defmacro deftest (name parameters &body body)
;;|   `(defun ,name ,parameters
;;|      (let ((*test-name* (append *test-name* (list ',name))))
;;|        ,@body)))
;;| (deftest test-+6 ()
;;|   (check22 (= (+ 1 2) 3)
;;| 	   (= (+ 1 2 3) 6)
;;| 	   (= (+ -1 -3) -4)))
;;| (fboundp 'test-+6)
;;| (test-+6)
;;| (deftest test-math ()
;;|   (test-arithmetic22))
;;| (test-math)
;;| ;;chapter ends
;;| ;;;;;;;;;;;;;
;;| 
;;chapter 10 numbers, characters ,strings
#\space
(setf *tc* #C(1 1))
(mod -9 2)
(rem -9 2)
;;error
;;(incf 8)
(1+ 8)
#\a
(characterp #\a)
(char/= #\a #\b)
(char<= #\a #\a)
"foo\bar"
(format t "foo\"bar")
(string= "anoopgr" "granoop" :start1 0 :end1 4
	 :start2 2 :end2 6)
(string/= "lisp" "lisssss")
;;uses dictionary order
(string< "abc" "abd")

;;chapter 11 collections
(vector 1)
(vector 1 2)
(make-array '(2))
(make-array '(2) :initial-element nil)
(make-array 2 :initial-element nil)
(make-array 5)
(make-array 5 :fill-pointer 0)
(defparameter *x* (make-array 5 :fill-pointer 0))
*x*
(vector-push 'a *x*)
(vector-push 'b *x*)
(vector-push 'c *x*)
*x*
(vector-pop *x*)
(vector-pop *x*)
(vector-pop *x*)
(defparameter *y*
  (make-array 5 :fill-pointer 0 :adjustable t))
(vector-push 'c *y*)
(vector-push 'c *y*)
(vector-push 'c *y*)
(vector-push 'c *y*)
(vector-push 'c *y*)
(vector-push-extend 'c *y*)
;;stopped at subtypes of vectors
(make-array 5 :fill-pointer 0 :adjustable t
	    :element-type 'character)
;;;;sequence:
;;;lists
;;;vectors
;;strings

;;below operations are applicable to all sequences:
(length "anoopgr")
(elt "anoopgr" 1)
(defparameter *xx* (vector 1 2 3))
(length *xx*)
(elt *xx* 0)
(elt *xx* 1)
(elt *xx* 2)
;;error (elt *xx* 3)
(setf (elt *xx* 0) 10)
*xx*
(count 1 #(1 2 1 2 3 1 2 3 4))
(remove 1 #(1 2 1 2 3 1 2 3 4))
(remove 1 '(1 2 1 2 3 1 2 3 4))
(remove #\a "foobarbaz")
(substitute 10 1 #(1 2 1 2 3 1 2 3 4))
(substitute 10 1 '(1 2 1 2 3 1 2 3 4))
(find 2 '(1 3 1 2 3 1 2 3 4))
(position 2 '(1 3 1 2 3 1 2 3 4))
(count 1 '(1 2 1 2 3 1 2 3 4) :test (complement #'>=))
(count "foo" #("foo" "bar" "baz" "foo") :test #'string=)
;;vector contains a bunch of lists:n
(find 'a #((a 10) (b 20) (c 30)) :key #'first)
(find 'a #((a 10) (b 20) (c 30) (a 40)) :key #'first
      :from-end t)
(find 'a #((a 10) (b 20) (c 30) (a 33)) :key #'first
      :start 1)
(count 1 #(1 2 3 1 2 3 1 2 3 1)
       :start 1 :end 7)
(remove #\a "Aaanoopaa")
(remove #\a "Aaanoopaa" :count 2)
(remove #\a "Aaanoopaa" :count 2 :from-end t)

(defparameter *v* #((a 10) (b 20) (c 30) (b 40) (a 55)))
(defun verbose-first (lst)
  (format t "~&Looking at ~A" lst)
  (car lst))
(count 'a *v* :key #'verbose-first)
(count 'a *v* :key #'verbose-first :from-end t)
;;side effects can vary due to keyword from-end in count
;; Funs: count, remove, substitute, position, find
;; :test :key :count :from-end :start :end

;;higher order variants of above
(count-if #'evenp '(1 2 3 4 5 6))
(count-if-not #'evenp '(1 2 3 4 5 6))
(count-if (complement #'evenp) '(1 2 3 4 5 6))
(position-if #'digit-char-p "anoop007")
(remove-if-not #'(lambda (x) (char= (elt x 0) #\f))
	       #("foo" "bar" "baz" "foom"))
(char-equal #\a #\A)
(char= #\a #\A)
;;equivalent to above:n
(remove-if
 (complement #'(lambda (x) (char= (elt x 0) #\f)))
	       #("foo" "bar" "baz" "foom"))
;;keywords for higher order ones
;; same as above except :test is obviously invalid
(remove-if-not #'alpha-char-p
	       #("foo" "bar" "1baz")
	       :key #'(lambda (x)
			(elt x 0)))
(remove-duplicates #(1 2 3
		     1 3 2
		     3 2 1))
;;whole sequence manipulations
;; copy-seq reverse
(defparameter *seq* #(a n o o p))
(reverse *seq*)
(setf test (copy-seq *seq*))
(concatenate 'vector #(anoop) #(gr))
(concatenate 'list #(anoop) #(gr))
(concatenate 'list #(anoop) '(gr))
;;error (concatenate 'string #("anoop") #("gr"))
(string< "anoop" "az")
(sort #("anoop" "a" "zoop") #'string<)
;; stable-sort -use C-h f
;; sort, stable-sort both are destructive

;;concatenate and sort = merge
(merge 'string #(#\a #\n #\o #\o #\p) #(#\c #\d #\e #\f)
       #'char< :key #'identity)

;;;subsequence manipulations
(defparameter *ss* "anoopgrunicorn")
(subseq *ss* 0 7)
;;subseq is setf able
(setf (subseq *ss* 7) "_|_")
(fill *ss* #\* :start 7)
(position #\b "foobarbaz")
(search "bar" "foobarbaz")
(mismatch "foobarbaz" "foom")
(mismatch "hbarbaz" "baz")
(mismatch "hbarbaz" "baz" :from-end t)
;;sequence predicates
;; some every notany notevery
(some #'evenp (vector 1 2 3 4))
(some #'evenp (vector 1 3 5 7))

(every #'evenp (vector 2 4 6 8))

;;no one is odd
(notany #'oddp (vector 2 4 6 8))

;;not everone satisfied predicate
(notevery #'oddp (vector 1 3 4 5))

(every #'< #(1 2 3 4) #(6 8 9 8))
(every #'< #(1 2 9 9) #(6 8 9 8))
(some #'< #(1 2 9 9) #(6 8 9 8))

;;sequence mapping functions

(map 'vector #'* #(1 2 3 4) #(10 9 8 7))
;;note that 'vector needs to be told

(setf a (vector 1 1 1)
      b (vector 2 2 2)
      c (vector 3 3 0))
(map-into a #'+ a b c)

;;reduce is always useful narrow down a sequence to a
;;  single number
(reduce #'+ (vector 1 2 3 4 5 6 7 8 9 10))
(reduce #'max (vector 1 2 3 4 5 6 7 8 9 10))
(reduce #'min (vector 1 2 3 4 5 6 7 8 9 10))

;;one unique keyword for reduce :initial-value
(reduce #'+ (vector 1 2) :initial-value 3)

(reduce #'max (vector 1 2) :initial-value 3)
;;is same as
(reduce #'max (vector 3 1 2))

(reduce #'max (vector 1 2) :initial-value 3 :from-end t)
;;is same as
(reduce #'max (vector 1 2 3))

;;;;hash tables
(eql "anoop" "an\oop")
(equal "anoop" "an\oop")

(defparameter *h* (make-hash-table))

;;order of args reverse of elt
(gethash 'foo *h*)
(setf (gethash 'foo *h*) 'quux)
(gethash 'foo *h*)

;;multiple-value-bind
(defun show-value (key hash-table)
  (multiple-value-bind (value present)
      (gethash key hash-table)
    (if present
	(format nil "Value = ~A and it is present" value)
	(format nil "Value = ~A and its absent" value))))
(show-value 'foo *h*)
(show-value 'anoop *h*)
;;doubt how to distinguish if something is a function
;;  or a macro
(setf (gethash 'anoop *h*) nil)
(show-value 'anoop *h*)
(setf (gethash 'anoop *h*) 'unicorn)
(show-value 'anoop *h*)
(remhash 'anoop *h*)
(clrhash *h*)

(setf (gethash 'india *h*) 'sucks)
(setf (gethash 'usa *h*) 'rocks)
(setf (gethash 'startup *h*) 'startup)
*h*

;;hash table iterate
(maphash #'(lambda (k v)
	     (format t "~&~A => ~A" k v))
	 *h*)
(maphash #'(lambda (k v)
	     (when (eql k v)
	       (remhash k *h*)))
	 *h*)

;;;;chapter 12
(cons 1 2)				;dotted pair
;;list = reference to a cons cell

;;functional programming

;;destructive operations : 1. for side effect 2. recycling

;;;2.recycling type
;;nreverse, nconc, delete, nsubstitute etc

;;recycling idioms
;;;1 - push+nreverse
(defun upto2 (max)
  (let ((result nil))
    (dotimes (i max)
      (push i result))
    (nreverse result)))
(upto2 8)
;;;2 - delete+setf
;;beware of below when there are shared structures
(setf *foo* (list 1 2 nil 3 nil 5))
(setf *foo* (delete nil *foo*))
*foo*
;;above 2 account for 80% of use of destructives in
;;  functional programming
;; above is not to be used when building 1st prototype

;;sort stable-sort merge are destructive on list arguments

;;;;list manipulating functions
;;a=car ; d=cdr
(setf *lst1* '(a (b1 b2 b3) c d e))
(car (cdr (car (cdr *lst1*))))
;;above is same as:
(cadadr *lst1*)
(last *lst1*)
(butlast *lst1*)

;;;;mapping
;;6 mapping functions specifically for lists
;;//to do : make some hand notes on funs studied
(mapcar #'(lambda (x) (* 2 x)) (list 1 2 3))
(mapcar #'+ (list 1 2 3) (list 10 20 30))
(mapcar #'identity (list 1 2 3 4))
(maplist #'identity (list 1 2 3 4))

;;mapcan:     Apply FUNCTION to successive elements of LIST. Return NCONC of FUNCTION
;;mapcon:     Apply FUNCTION to successive CDRs of lists. Return NCONC of results.

(mapcan #'identity '((1) (2)))

(mapcon #'(lambda (x) (list 'start x 'end)) '(1 2 3 4))
(mapcon #'(lambda (x) (list x)) '(1 2 3 4))

;;dont worry much about remembering such above details
;; consult hyperspec or simplified online reference when
;;   required
;; or use C-c C-d d   or  C-h f  or C-h v

;;chapter 13
;;lists and cons cells are not always synonyms
;;cons cells can mean higher data strucs like trees etc

;;beyond lists: other uses for cons cells

;;;;trees
;;lists vs trees: different way of traversal
;;lists : car referenced traversal
;;trees : car and cdr referenced
;;        so traversed values in trees are all atomic

(setf *lst2* (list (list 1 2) (list 3 4) (list 5 6)))
(setf *lst3* (copy-list *lst2*))
(setf (caar *lst3*) 'anoop)
*lst2*

(setf *lst2* (list (list 1 2) (list 3 4) (list 5 6)))
(setf *lst3* (copy-tree *lst2*))
(setf (caar *lst3*) 'anoop)
*lst2*
(sdraw *lst2*)
;;tree-equal subst and family: subst-if etc
;;nsubst

;;//to do: learn profiling for any language you want to master
;;  helps in optimising the 1st prototype


;;;;sets
;;adjoin
(defparameter *set* ())
(setf *set* (adjoin 1 *set*))
;;pushnew macro = adjoin + setf
(pushnew 3 *set*)
(member 2 *set*)
(member 2 '(1 2 3 5))
;;member-if member-if-not ;set operations defined on lists
;;adjoin, intersection, union, set-difference, set-exclusive-or
;;all have a n* counterpart

(subsetp '(1 2) '(1 8 9 2 7))

;;;;lookup tables - assoc list, property list
;;if table grows large better to switch to hash tables

;;assoc list
(setf *assoc* '((a . 1) (b . 2) (c . 3)))
(assoc 'a *assoc*)
(cons (cons 'd 4) *assoc*)
;;acons macro
(acons 'e 5 *assoc*)
;;will have to setf *assoc* manually

;;assoc-if assoc-if-not
;;rassoc rassoc-if rassoc-if-not

;;copy-alist = contain same key and values

(pairlis '(1 2 3) '(a b c))

;;property list
;;anoop = dont use these

;;;;destructuring bind
;;how it works:
;;eval the list of values to a list
;;destructure the above list and assign to var names
;;eval body
(destructuring-bind (x y z) (list 1 2 8)
  (list :x x :y y :z z))
(destructuring-bind (x y z) (list 1 (list 2 20) 3)
  (list :x x :y y :z z))
(destructuring-bind (x (y1 y2) z) (list 1 (list 2 20) 3)
  (list :x x :y1 y1 :y2 y2 :z z))
(destructuring-bind (x (y1 &optional y2) z)
    (list 1 (list 2 20) 3)
  (list :x x :y1 y1 :y2 y2 :z z))
(destructuring-bind (x (y1 &optional y2) z)
    (list 1 (list 2) 3)
  (list :x x :y1 y1 :y2 y2 :z z))

;;notice below carefully:
(destructuring-bind (&key x y z) (list :x 1 :y 2 :z 3)
  (list :x x :y y :z z))
(destructuring-bind (&key x y z) (list :z 1 :y 2 :x 3)
  (list :x x :y y :z z))

;;&whole
(destructuring-bind (&whole whole &key x y z)
    (list :y 2 :x 1 :z 3)
  (list :x x :y y :z z 'whole whole))
(destructuring-bind (&whole whole &key x y z)
    (list :y 2 :x 1 :z 3)
  (list :x x :y y :z z :whole whole))

;;;;;;;;;;;;;;;;;;;;
;;chapter14 - files and file I/O

;; stream, pathname
;;// to do: copy-paste just the outlines from a pdf into a
;;   lisp file

(let ((stream-name0 (open "~/pcl/fileio-example.txt"
			 :if-does-not-exist nil)))
  (format t "~&~A" (read-line stream-name0 ))
  (close stream-name0))
(let ((stream-name0 (open "~/pcl/fileio-example.txt"
			  :if-does-not-exist nil)))
  (do ((print-me (read-line stream-name0 nil)
		 (read-line stream-name0 nil)))
      ((eql print-me nil) 'ended)
    (format t "~&~A *|*" print-me))
  (close stream-name0))
;; read, read-char, read-line
(let ((stream-name0 (open "~/pcl/fileio-example.txt"
			  :if-does-not-exist nil)))
  (do ((print-me (read-char stream-name0 nil)
		 (read-char stream-name0 nil)))
      ((eql print-me nil) 'ended)
    (format t "~A *|*" print-me))
  (close stream-name0))
(let ((stream-name0 (open "~/pcl/fileio-example.txt"
			  :if-does-not-exist nil)))
  (do ((print-me (read stream-name0 nil)
		 (read stream-name0 nil)))
      ((eql print-me nil) 'ended)
    (format t "~&~A" print-me))
  (close stream-name0))
;; capitalize M-- M-u
;; read is the same as R in REPL

;;use (print ) to print to file in readable form
;;;;reading binary data
;;read-byte
;;;;bulk
;;read-sequence

;;;;file-output
(let ((out0 (open "/home/anoop/pcl/fileio-example.txt"
		  :direction :output
		  :if-exists :append)))
  (format out0 "~&;;If 10,000 hrs; 12 hrs/day were easy~% ;;everyone would do it and become a master!!!")
  (close out0))
(with-open-file (s0 "/home/anoop/pcl/fileio-example.txt"
		    :direction :output :if-exists :append)
  (format s0 "~&;;;****input****"))

;;;;filenames
(pathname-directory
 (pathname "/home/anoop/pcl/fileio-example.txt"))
(pathname-name
 (pathname "/home/anoop/pcl/fileio-example.txt"))
(pathname-type
 (pathname "/home/anoop/pcl/fileio-example.txt"))
;;constructing new pathnames:
(make-pathname :directory '(:ABSOLUTE "home" "anoop" "pcl")
	       :name "fileio-example"
	       :type "txt")
;;above is not portable

;;make pathnames relative to user input pathnames
;;this is very portable
(setf *p1*
      (make-pathname :type "html"
	       :defaults 
	       (pathname
		"/foo/bar/baz.txt")))
(setf *p2*
      (make-pathname
	       :directory '(:relative "backups")
               :defaults
	       (pathname
		"/foo/bar/baz.txt")))

;;analogy merge=addition kind of
(merge-pathnames (pathname "foo/bar.html")
		 (pathname "/www/html/"))

;;analogy enough-namestring=substraction, relative velocity
;;get pathname relative to the 2nd input directory
(enough-namestring (pathname "/www/html/foo/bar/baz.html")
		   (pathname "/www/"))

;;using merge and enough-namestring together:
(merge-pathnames
 (enough-namestring (pathname "/www/html/foo/bar/baz.html")
		    (pathname "/www/"))
 (pathname "/www-backups/"))

;;2 representations of directory names
(make-pathname :directory '(:absolute "foo")
	       :name "bar")
(make-pathname :directory '(:absolute "foo" "bar"))
;; trailing / makes the difference

;;;;interactiong with the filesystem
;;;funs:
;;probe-file, directory, delete-file, rename-file, ensure-directories-exist, file-write-date, file-author, file-length
(with-open-file (in0 "/home/anoop/pcl/fileio-example.txt"
		     :element-type '(unsigned-byte 8))
  (file-length in0))
;;verify with ls -lh

;;;;other kinds of I/O
;; string streams:
;; ex:string to float 
(let ((s (make-string-input-stream "1.23")))
  (unwind-protect (read s)
    (close s)))

;;make-string-output-stream
;;get-output-stream-string
;;above rarely used because:
;;above 2 combined into a nice macro:
;;with-input-from-string ~ similar to with-open-file
;;with-output-to-string ~ 

;;rewriting previous w/o unwind-protect headache
(with-input-from-string (s "1.23")
  (read s))

(with-output-to-string (out0)
  (format out0 "hello anoop")
  (format out0 "~&will start with discrete math soon")
  (format out0 " ~S" (list 1 2 3)))

;;page 176
;;it lists some more stream functions, refer when needed


;;need to revise chapter 15 again properly
;; need to try out examples on the newly defined funs
;;;;;;;;;;;;;;;;;;;
;;chapter15
;;Practical: A portable pathname library

(in-package :com.gigamonkeys.pathnames)

;;list-directory
(defun component-present-p (value)
  "not nil , not :unspecific?"
  (and (not (eql value nil)) (not (eql value :unspecific))))
(defun directory-pathname-p (p)
  "p is in directory format of name=:wild type=:wild?"
  (and
   (not (component-present-p (pathname-name p)))
   (not (component-present-p (pathname-type p)))
   p))
(directory (make-pathname :name :wild :type :wild
			  :defaults
			  (pathname "/home/anoop/pcl/")))
(directory (setf *p1* (make-pathname :name nil :type nil
			  :defaults
			  (pathname "/home/anoop/pcl/"))))
(setf *p* (make-pathname :name :wild :type :wild
			  :defaults
			  (pathname "/home/anoop/pcl/")))
(setf *p1* (make-pathname :name nil :type nil
			  :defaults
			  (pathname "/home/anoop/pcl/")))
(directory-pathname-p *p*)
(directory-pathname-p *p1*)

(defun pathname-as-directory (name)
  (let ((pathname (pathname name)))
    (when (wild-pathname-p pathname)
      (error "Can't reliably convert wild pathnames."))
    (if (not (directory-pathname-p name))
	(make-pathname
	 :directory (append (or (pathname-directory pathname)
				(list :relative))
			    (list (file-namestring pathname)))
	 :name nil
	 :type nil
	 :defaults pathname)
	pathname)))
(defun directory-wildcard (dirname)
  (make-pathname
   :name :wild
   :type #-clisp :wild #+clisp nil
   :defaults (pathname-as-directory dirname)))
(defun list-directory1 (dirname)
  (when (wild-pathname-p dirname)
    (error "CAn only list cocrete directory names."))
  (directory (directory-wildcard dirname)))

(defun list-directory (dirname)
  (when (wild-pathname-p dirname)
    (error "Can only list concrete directory names."))
  (let ((wildcard (directory-wildcard dirname)))

    #+(or sbcl cmu lispworks)
    (directory wildcard)

    #+openmcl
    (directory wildcard :directories t)

    #+allegro
    (directory wildcard :directories-are-files nil)

    #+clisp
    (nconc
     (directory wildcard)
     (directory (clisp-subdirectories-wildcard wildcard)))

    #-(or sbcl cmu lispworks openmcl allegro clisp)
    (error "list-director not implemented")))

#+clisp
(defun clisp-subdirectories-wildcard (wildcard)
  (make-pathname
   :directory (append (pathname-directory wildcard)
		      (list :wild))
   :name nil
   :type nil
   :defaults wildcard))
(list-directory "~/pcl")

;;;;testing file's existence

(defun file-exists-p (pathname)
  #+(or sbcl lispworks openmcl)
  (probe-file pathname)

  #+(or allegro cmu)
  (or (probe-file (pathname-as-directory pathname))
      (probe-file pathname))

  #+clisp
  (or (ignore-errors
	(probe-file (pathname-as-file pathname)))
      (ignore-errors
	(let ((directory-form (pathname-as-directory pathname)))
	  (when (ext:probe-directory directory-form)
	    directory-form))))

  #-(or sbcl cmu lispworks openmcl allegro clisp)
  (error "list-directory not implemented"))

(defun pathname-as-file (name)
  (let ((pathname (pathname name)))
    (when (wild-pathname-p pathname)
      (error "Can't reliably convery wild pathnames."))
    (if (directory-pathname-p name)
	(let* ((directory (pathname-directory pathname))
	       (name-and-type (pathname (first (last directory)))))
	  (make-pathname
	   :directory (butlast directory)
	   :name (pathname-name name-and-type)
	   :type (pathname-type name-and-type)
	   :defaults pathname))
	pathname)))

;;;;walking a directory tree
(defun walk-directory (dirname fn &key directories
				    (test (constantly t)))
  (labels
      ((walk (name)
	 (cond
	   ((directory-pathname-p name)
	    (when (and directories (funcall test name))
	      (funcall fn name))
	    (dolist (x (list-directory name)) (walk x)))
	   ((funcall test name) (funcall fn name)))))
    (walk (pathname-as-directory dirname))))

(in-package COMMON-LISP-USER)
;;;chapter ends!!!!!

















