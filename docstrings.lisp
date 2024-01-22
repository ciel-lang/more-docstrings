(uiop:define-package :more-docstrings
    (:use :cl))

(in-package :more-docstrings)

#|
Add more documentation and add examples to the docstrings.

Now, when we read a function documentation from our editor or with the
built-in `documentation` function, we can learn more about it, and see
examples. We have less the need to reach for external resources.

The goal is still to ease the first contact of newcomers with CL.
For example, give examples on how to use MAP, MAPCAR, MAPCAN.

XXX: gotchas

- if we quickload :ciel twice, the docstrings
are appended twice too :S The hash-table cache doesn't help in that
case.
- we are modifying the symbols in the :cl package, not the ones in :ciel.

|#

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; One function to do the job:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar *docstrings-cache* (make-hash-table)
  "Cache the original docstring of functions and macros we are augmenting.
  Mainly to ease our tests at the REPL.")

(defun documentation-with-cache (symbol &optional (doc-type 'function))
  (let ((cached (gethash symbol *docstrings-cache*)))
    (if cached
        cached

        (let ((doc (documentation symbol doc-type)))
          (setf (gethash symbol *docstrings-cache*)
                ;; don't store a NIL docstring.
                (or doc ""))
          doc))))

(defun docstring-append (symbol s &optional (doc-type 'function))
  "Add S to the docstring of SYMBOL (to designate a function or a macro).
  DOC-TYPE is the required argument of DOCUMENTATION, by default 'function (for functions and macros), otherwise use 'variable."
  (let ((doc (documentation-with-cache symbol doc-type)))
    (setf (documentation symbol doc-type)
          (str:concat doc s))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Now use it.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; mapcar
(docstring-append 'mapcar "

For example:

(mapcar #'+ '(1 2 3) '(10 20 30))  ;; => (11 22 33)

(mapcar (lambda (x)
          (format t \"~a is ~R~&\" x x))
        '(1 2 3))
;; =>
1 is one
2 is two
3 is three
(NIL NIL NIL)
")


;;; mapcan
(docstring-append 'mapcan "

NCONC concatenates lists destructively.")


;;; sort
(docstring-append 'sort "

Since SORT is destructive, use COPY-LIST:

(setq mylist (list 1 3 2))
(sort (copy-list mylist) #'<)

See also STABLE-SORT.")


;;; loop
(docstring-append 'loop "
The basic LOOP structure is

(loop for x in (list x y z)
   do …)

\"do\" is for side effects.

Use \"collect\" to return results:

(loop for x in (list 1 2 3)
  collect (* x 10))

To iterate over arrays, use \"across\" instead of \"in\".

To iterate over hash-tables… try MAPHASH first :D

For many examples, see the CL Cookbook:
https://lispcookbook.github.io/cl-cookbook/iteration.html")


;;; maphash
(docstring-append 'maphash "

Example:

(maphash (lambda (key value)
           (format t \"key is: ~a, value is: ~a~&\" key value))
         (dict :a 'one))
;; => key is: A, value is: ONE")


;;; defun
(docstring-append 'defun "

Example:

(defun hello (name)
  \"Say \\\"hello\\\" to NAME.\"
  (format t \"Hello ~a!\" name))

Define named parameters with &key:

(defun hello (name &key lisper)
  ...)

and use it like so: (hello \"you\" :lisper t)

Key parameters are NIL by default. Give them another default value like this:

(defun hello (name &key (lisper t))
  ...)

Read more:
https://gigamonkeys.com/book/functions.html
https://lispcookbook.github.io/cl-cookbook/functions.html")


;;; defmacro
(docstring-append 'defmacro "Macros operate on code, which they see as lists of lists of symbols.

Macros, unlike functions, do not evaluate their arguments.  They
expand (at compile time) into another piece of code, that will
eventually be evaluated.

First rule for macros: don't write a macro when a function can do.

Example macros: DEFUN LOOP SETF WITH-OPEN-FILE

See also: QUOTE BACKQUOTE GENSYM MACROEXPAND

Read more:
https://lispcookbook.github.io/cl-cookbook/macros.html
https://gigamonkeys.com/book/macros-standard-control-constructs.html
https://www.youtube.com/watch?v=ygKXeLKhiTI Little bits of Lisp video
")

;;; defclass
(docstring-append 'defclass "The macro defclass defines a new named class. It returns the new class object as its result.

Example:

    (defclass living-being () ())

    (defclass person (living-being)
      ((name
        :initarg :name
        :initform \"\"
        :accessor name)
       (lisper
        :initarg :lisper
        :initform nil
        :accessor lisper
        :documentation \"Set to non-nil if this person fancies Lisp.\")))

Slots are unbound by default, here we prefer them to be the empty string and nil.

An :accessor creates a generic method. You can have the same accessor name in different classes.

Create an instance of that class with MAKE-INSTANCE:

    (make-instance 'person :name \"Alice\" :lisper t)

Define how to pretty-print an object with PRINT-OBJECT.

After we change a class definition (slots are modified, added or removed), we can control how an object is updated with UPDATE-INSTANCE-FOR-REDEFINED-CLASS.

Read more:
https://lispcookbook.github.io/cl-cookbook/clos.html
https://cl-community-spec.github.io/pages/defclass.html
")

;;; to be continued.

(docstring-append 'print-object "The generic function print-object writes the printed representation of object to stream. The function print-object is called by the Lisp printer; it should not be called by the user.

Example:

   (defmethod print-object ((obj person) stream)
      (print-unreadable-object (obj stream :type t :identity t)
        (with-slots (name lisper) obj
          (format stream \"~a, lisper: ~a\" name lisper))))

   (make-instance 'person :name \"Alice\")
   ;; =>
   #<PERSON Alice, lisper: NIL {1007277633}>
   (1) (2)                     (3)
   1 tells the reader that this object can't be read back in
   2 is the object type
   3 is the object identity (address).

Read more:
https://cl-community-spec.github.io/pages/print_002dobject.html
https://lispcookbook.github.io/cl-cookbook/clos.html#pretty-printing
")
