(cl:in-package #:cl-jpeg-tests)

(in-suite :cl-jpeg)

(defun test-image (filename)
  (reduce #'merge-pathnames (list filename "images/")
          :from-end t
          :initial-value (asdf:component-pathname
                          (asdf:find-system "cl-jpeg-tests"))))

(defun output-image (filename)
  (reduce #'merge-pathnames (list filename "output/")
          :from-end t
          :initial-value (asdf:component-pathname
                          (asdf:find-system "cl-jpeg-tests"))))

(ensure-directories-exist (output-image ""))

(defun flatten-array (arr)
  (make-array (reduce #'* (array-dimensions arr))
              :displaced-to arr
              :element-type (array-element-type arr)))

(defun array- (arr1 arr2)
  (let ((flat-arr1 (flatten-array arr1))
        (flat-arr2 (flatten-array arr2)))
    (map 'vector #'- flat-arr1 flat-arr2)))

(defun sum-of-element-wise-differences (arr1 arr2)
  (reduce #'+ (array- arr1 arr2)))

(defun array-element-sum (arr)
  (reduce #'+ arr))

(defparameter *gray-q-tabs* (vector jpeg::+q-luminance+))

(test read-8-bit-gray
  (let* ((file (test-image "truck-gray.jpeg"))
         (img (jpeg:decode-image file)))
    (is (equal (type-of img) '(simple-array (unsigned-byte 8) (10880))))
    (is (= (array-element-sum img) 1132807))))

(test write-8-bit-gray
  (let* ((file (test-image "truck-gray.jpeg")))
    (multiple-value-bind (img height width ncomp)
        (jpeg:decode-image file)
      (is (= height 85))
      (is (= width 128))
      (is (= ncomp 1))
      (let ((out (output-image "truck-gray2.jpeg")))
        (encode-image out img ncomp height width :q-tabs *gray-q-tabs*)
        (let ((input-img (jpeg:decode-image out)))
          ;; the JPEG images won't be identical, so let's see if we
          ;; take the difference between the two images it ends up
          ;; being less than some arbitrary threshold
          (let ((img-diff (abs (sum-of-element-wise-differences img input-img)))
                (difference-threshold (* (length img) 2)))
            (is (< img-diff difference-threshold))))))))

(test read-8-bit-rgb
  (let* ((file (test-image "truck.jpeg"))
         (img (jpeg:decode-image file)))
    (is (equal (type-of img) '(simple-array (unsigned-byte 8) (2016))))
    (is (= (array-element-sum img) 224236))))

(test write-8-bit-rgb
  (let* ((file (test-image "truck.jpeg")))
    (multiple-value-bind (img height width ncomp)
        (jpeg:decode-image file)
      (is (= height 21))
      (is (= width 32))
      (is (= ncomp 3))
      (let ((out (output-image "truck.jpeg")))
        (encode-image out img ncomp height width)
        (let ((input-img (jpeg:decode-image out)))
          ;; the JPEG images won't be identical, so let's see if we
          ;; take the difference between the two images it ends up
          ;; being less than some arbitrary threshold
          (let ((img-diff (abs (sum-of-element-wise-differences img input-img)))
                (difference-threshold (* (length img) 2)))
            (is (< img-diff difference-threshold))))))))
