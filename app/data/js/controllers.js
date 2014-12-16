var ciControllers = angular.module("ciControllers", []);

ciControllers.controller("ProjectsCtrl", function ($scope, $http) {
    var promise = $http.get("/api/projects");

    promise.success(function (response) {
        $scope.projects = response;
    });
});

ciControllers.controller("ProjectDetailCtrl", function ($scope, $http, $routeParams) {
    $scope.projectID = $routeParams.projectID;

    var promise = $http.get("/api/projects/" + $scope.projectID + "/pipelines");
    promise.success(function (response) {
        $scope.project = response;
    });

    $scope.taskMarkup = function (pipelineStatus, pipelineTask, step) {
        if (pipelineStatus == 'ready') {
            return 'bg-active';
        } else if (pipelineStatus == 'complete') {
            return 'bg-success';
        } else if (pipelineTask == step.name) {
            if (pipelineStatus == 'running') {
                return 'bg-warning';
            } else {
                return 'bg-danger';
            }
        } else if (step.name < pipelineTask) {
            return 'bg-success';
        } else {
            console.log(pipelineStatus, pipelineTask, step);
            return 'bg-active';
        }
    };
    $scope.clickStep = function (pipeline, step) {
        pipeline.stepDetail = pipeline.stepDetail == step ? undefined : step;
    };
    $scope.showLogFile = function (pipeline, step) {
        var promise = $http({
            method: 'GET',
            url: '/api/projects/' + $scope.projectID + '/pipelines/' + pipeline.name + '/tasks/' + step.name + '/log'
        });
        promise.success(function (data, status, headers, config) {
            step.log = data;
        });
        promise.error(function (data, status, headers, config) {
            step.log = 'Unable to load log file: ' + data;
        });
    };
});
