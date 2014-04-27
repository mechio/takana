var gulp = require('gulp'),
  connect = require('gulp-connect');

var sass = require('gulp-sass')
var watch = require('gulp-watch')

var paths = {
  scss: './scss/*.scss'
};

gulp.task('sass', function () {
    gulp.src(paths.scss)
        .pipe(sass())
        .pipe(gulp.dest('./css'));
});


gulp.task('connect', function() {
  connect.server({
    livereload: true
  });
});

gulp.task('html', function () {
  gulp.src('./app/*.html')
    .pipe(connect.reload());
});


gulp.task('watch', function() {
  gulp.watch([paths.scss], ['sass']);
  gulp.watch(['./app/*.html'], ['html']);  
});




gulp.task('default', ['connect']);
