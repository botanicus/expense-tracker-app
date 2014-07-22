var app = angular.module('app', ['ngRoute', 'ui.bootstrap', 'services']);

app.config(function ($locationProvider, $routeProvider) {
  $routeProvider.when('/', {
    controller: 'HomeController',
    templateUrl: '/templates/home.html'
  }).
  when('/sign-up', {
    title: 'Sign Up For Expenses Tracker',
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
app.run(function ($location, $rootScope, $location) {
  $rootScope.$on('$routeChangeSuccess', function (event, current, previous) {
    $rootScope.title = current.$$route ? current.$$route.title : null;

    $rootScope.location = $location.path();
    console.log("SET location to " + $rootScope.location)
  });
});

app.controller('MainController', function ($scope) {
});

app.controller('HomeController', function ($scope) {
});

app.controller('SignUpController', function ($scope, $location, $modal, User) {
  $scope.user = {};

  $scope.register = function (user) {
    var user = new User(user);
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
      console.log(element[0].value)
      scope.$watch(attrs.ngModel, function () {
        if (element[0].value) {
          var data = {username: element[0].value}
          $http.post('/api/username-check', data).
            success(function (data, status, headers, cfg) {
              c.$setValidity('unique', data.available);
          });
        };
      });
    }
  }
});

// TODO: This should observe password and update on its
// change as well.
app.directive('valueMatch', function () {
  return {
    restrict: 'A',
    require: 'ngModel',

    link: function (scope, element, attrs, ctrl) {
      var originInputName = attrs.valueMatch;
      var originElement = scope.signupForm[originInputName];
      var inputElement = element[0];

      var valueMatchValidatorGenerator = function (retFn) {
        return function (value) {
          if (inputElement.value == '' && originElement.$viewValue == undefined) {
            ctrl.$setValidity('valueMatch', true);

            return retFn(false, undefined);
          } else {
            var validity = inputElement.value == originElement.$viewValue;
            ctrl.$setValidity('valueMatch', validity);

            return retFn(validity, value);
          };
        };
      };

      // This is called every time value is parsed
      // into the model when the user updates it.
      ctrl.$parsers.unshift(valueMatchValidatorGenerator(function (valid, value) {
        // if it's valid, return the value to the model,
        // otherwise return undefined.
        return valid ? value : undefined;
      }));

      // This is called every time value is updated on the DOM element.
      ctrl.$formatters.unshift(valueMatchValidatorGenerator(function (valid, value) {
        // Return the value or nothing will be written to the DOM.
        return value;
      }));
    }
  };
});
