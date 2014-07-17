var app = angular.module('app', ['ngRoute', 'ui.bootstrap']);

app.config(function ($locationProvider, $routeProvider) {
  $routeProvider.when('/', {controller: 'HomeController'});

  $routeProvider.otherwise({'redirectTo': '/'});

  $locationProvider.html5Mode(true);
});

/* Set up the title. */
app.run(function ($location, $rootScope) {
  $rootScope.$on('$routeChangeSuccess', function (event, current, previous) {
    $rootScope.title = current.$$route ? current.$$route.title : null;
  });
});

app.controller('MainController', function ($scope) {
});

app.controller('HomeController', function ($scope) {
});
