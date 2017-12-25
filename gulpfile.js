const gulp = require('gulp');
const elm = require('gulp-elm');
const gutil = require('gulp-util');
const plumber = require('gulp-plumber');
const connect = require('gulp-connect');

const paths = {
    dest: 'dist',
    elm: 'src/*.elm',
    static: 'stc/*.{html,css}'
};

gulp.task('elm-init', elm.init);

gulp.task('elm', ['elm-init'], () => gulp
    .src(paths.elm)
    .pipe(plumber())
    .pipe(elm())
    .pipe(gulp.dest(paths.dest))
);

gulp.task('static', () => gulp
    .src(paths.static)
    .pipe(plumber()
    .pipe(gulp.dest(paths.dest))
));

gulp.task('watch', () => {
    gulp.watch(paths.elm, ['elm']);
    gulp.watch(paths.static, ['static']);
});

gulp.task('connect', () => {
    connect.server({
        root: 'dist',
        port: '3000'
    })
});

gulp.task('build', ['elm', 'static']);
gulp.task('default', ['connect', 'build', 'watch']);