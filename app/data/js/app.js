var ciApp = angular.module("basicCI", [
    'ngRoute',
    'ui.bootstrap',
    'ciControllers'
]);

ciApp.config(['$routeProvider',
    function ($routeProvider) {
        $routeProvider.
            when('/projects', {
                templateUrl: 'partials/project-list.html',
                controller: 'ProjectsCtrl'
            }).
            when('/projects/:projectID', {
                templateUrl: 'partials/project-detail.html',
                controller: 'ProjectDetailCtrl'
            }).
            otherwise({
                redirectTo: '/projects'
            });
    }]);
