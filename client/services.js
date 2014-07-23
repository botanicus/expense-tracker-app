var services = angular.module('services', ['ngResource']);

services.factory('User', function ($resource) {
  return $resource('/api/users/:username');
});

services.factory('Expense', function ($resource) {
  return $resource('/api/expenses/:id');
});
