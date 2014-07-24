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
    title: 'Log Into Expenses Tracker',
    controller: 'LoginController',
    templateUrl: '/templates/login.html'
  }).
  when('/dashboard', {
    title: 'Expenses Tracker Dashboard',
    controller: 'DashboardController',
    templateUrl: '/templates/dashboard.html',
    resolve: {
      expenses: function (Expense) {
        return Expense.query();
      }
    }
  });

  $routeProvider.otherwise({'redirectTo': '/'});

  $locationProvider.html5Mode(true);
});

app.factory('AuthInterceptor', function ($window, $location, $q) {
  return {
    request: function (config) {
      config.headers = config.headers || {};
      if ($window.sessionStorage.token) {
        var token = $window.sessionStorage.token;
        var value = 'JWT token="' + token + '"';
        config.headers.Authorization = value;
      }
      return config || $q.when(config);
    },
    response: function (response) {
      if (response.status === 401) {
        $location.path('/login');
      };
      return response || $q.when(response);
    }
  };
});

// Register the AuthInterceptor.
app.config(function ($httpProvider) {
  $httpProvider.interceptors.push('AuthInterceptor');
});

/* Set up the title. */
app.run(function ($location, $rootScope, $location) {
  $rootScope.$on('$routeChangeSuccess', function (event, current, previous) {
    $rootScope.title = current.$$route ? current.$$route.title : null;
    $rootScope.location = $location.path();
  });
});

app.controller('MainController', function ($rootScope, $scope, $http, $window, $location) {
  if ($window.sessionStorage.username) {
    $rootScope.username = $window.sessionStorage.username;
  };

  $scope.logIn = function (credentials) {
    $http
      .post('/api/sessions', credentials)
      .success(function (data, status, headers, config) {
        // Let's use the session storage, it gets wiped out when
        // the tab is closed.
        $window.sessionStorage.token = data.token;
        $window.sessionStorage.username = credentials.username;
        $rootScope.username = credentials.username;

        $location.path('/dashboard');
      })
      .error(function (data, status, headers, config) {
        delete $window.sessionStorage.token;
        delete $window.sessionStorage.username;
        delete $rootScope.username;
        $scope.errorMessage = data.message;
      });
  };
});

app.controller('LoginController', function ($scope) {
  $scope.credentials = {};

  // logIn is defined in the MainController.
});

app.controller('HomeController', function ($scope) {
});

app.controller('DashboardController', function ($scope, $modal, Expense, expenses) {
  $scope.expenses = expenses;

  $scope.showExpenseForm = function (expense)  {
    var modalInstance = $modal.open({
      templateUrl: 'templates/expense-form.html',
      controller: 'ExpenseFormController',
      resolve: {
        expense: function () {
          return expense || new Expense();
        }
      }
    });

    modalInstance.result.then(function (expense) {
      // Since Set won't be available until ES6 ...
      if ($scope.expenses.indexOf(expense) == -1) {
        $scope.expenses.push(expense);
      };
    });
  };

  $scope.editExpense = function (expense) {
    $scope.showExpenseForm(expense);
  };

  $scope.deleteExpense = function (expense) {
    expense.$delete({id: expense.id}, function () {
      var index = $scope.expenses.indexOf(expense);
      if (index > -1) {
        $scope.expenses.splice(index, 1);
      }
    });
  }
});

app.controller('ExpenseFormController', function ($scope, expense, $modalInstance) {
  $scope.expense = expense;

  $scope.saveExpense = function (expense) {
    expense.$save(function () {
      $modalInstance.close(expense);
    });
  };

  $scope.cancel = function () {
    $modalInstance.dismiss('cancel');
  };
});

app.controller('SignUpController', function ($scope, $modal, $location, User) {
  $scope.user = {};

  $scope.register = function (user) {
    var user = new User(user);
    user.$save();
    $scope.logIn(user);
    $location.path('/dashboard');
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

// Adapted from http://www.benlesh.com/2012/12/angular-js-custom-validation-via.html
//
// TODO: Do not hardcode signupForm.
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

      scope.$watch(attrs.watchModel, function (value) {
        var fn = valueMatchValidatorGenerator(function () {});
        fn(value);
      });

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
