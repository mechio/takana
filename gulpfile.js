var gulp  = require('gulp'),
    watch = require('gulp-watch'),
    docco = require("gulp-docco");


gulp.task('docs', function () {
  gulp.src("./lib/**/*.coffee")
    .pipe(docco())
    .pipe(gulp.dest('./docs/'))
});

gulp.task('watch', function() {
  gulp.watch(['./lib/**/*.coffee'], ['docs']);  
});

gulp.task('default', ['docs']);