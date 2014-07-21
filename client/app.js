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

app.controller('SignUpController', function ($scope, $location, $modal, User) {
  $scope.user = {};

  $scope.register = function (credentials) {
    var user = new User(credentials);
    user.$save();
    $location.path('/app');
  };

  $scope.showTC = function () {
    $scope.modalInstance = $modal.open({
      templateUrl: 'templates/toc.html',
      scope: $scope
    });
  };

  $scope.closeModal = function () {
    $scope.modalInstance.close();
  }
});


// TODO: Extract this elsewhere.
// Shamelessly stolen from http://www.ng-newsletter.com/posts/validations.html.
// TODO: prevent form submission until checked.
app.directive('unique', function ($http) {
  return {
    require: 'ngModel',
    link: function(scope, element, attrs, c) {
      scope.$watch(attrs.ngModel, function () {
        $http({
          method: 'POST',
          url: '/api/username-check/' + attrs.unique,
          data: {'field': attrs.unique}
        }).success(function(data, status, headers, cfg) {
          c.$setValidity('unique', data.isUnique);
        }).error(function(data, status, headers, cfg) {
          c.$setValidity('unique', false);
        });
      });
    }
  }
});
