var services = angular.module('services', ['ngResource']);

services.factory('User', function ($resource, $location) {
  return $resource('/api/users/:username');
});
