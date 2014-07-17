var app = angular.module('app', ['ngRoute', 'ui.bootstrap', 'services']);

app.config(function ($locationProvider, $routeProvider) {
  $routeProvider.when('/', {
    controller: 'HomeController',
    templateUrl: '/templates/home.html'
  }).
  when('/sign-up', {
    controller: 'SignUpController',
    templateUrl: '/templates/sign-up.html'
  }).
  when('/login', {
    // TODO: How to go about it?
    controller: 'SignUpController',
    templateUrl: '/templates/sign-up.html'
  });

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

app.controller('SignUpController', function ($scope, $location, User) {
  $scope.user = {};

  $scope.register = function () {
    var user = new User($scope.user);
    user.$save();
    // TODO: Log in.
    $location.path('/app');
  };
});
