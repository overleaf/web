define [
	"base"
], (App) ->
	App.controller "FileTreeEntityController", ["$scope", "ide", "$modal", ($scope, ide, $modal) ->
		$scope.select = () ->
			ide.fileTreeManager.selectEntity($scope.entity)
			$scope.$emit "entity:selected", $scope.entity

		$scope.inputs =
			name: $scope.entity.name

		$scope.startRenaming = () ->
			$scope.entity.renaming = true

		$scope.finishRenaming = () ->
			delete $scope.entity.renaming
			name = $scope.inputs.name
			if !name? or name.length == 0
				$scope.inputs.name = $scope.entity.name
				return
			ide.fileTreeManager.renameEntity($scope.entity, name)

		$scope.$on "rename:selected", () ->
			$scope.startRenaming() if $scope.entity.selected

		$scope.openDeleteModal = () ->
			$modal.open(
				templateUrl: "deleteEntityModalTemplate"
				controller:  "DeleteEntityModalController"
				scope: $scope
			)

		$scope.$on "delete:selected", () ->
			$scope.openDeleteModal() if $scope.entity.selected
		
		$scope.iconTypeFromName = (name) ->
			ext = name.split(".").pop()?.toLowerCase()
			if ext in ["png", "pdf", "jpg", "jpeg", "gif"]
				return "image"
			else if ext in ["csv", "xls", "xlsx"]
				return "table"
			else if ext in ["py", "r"]
				return "file-text"
			else
				return "file"
	]

	App.controller "DeleteEntityModalController", [
		"$scope", "ide", "$modalInstance",
		($scope,   ide,   $modalInstance) ->
			$scope.state =
				inflight: false

			$scope.delete = () ->
				$scope.state.inflight = true
				ide.fileTreeManager
					.deleteEntity($scope.entity)
					.success () ->
						if $scope.entity?.type == "output"
							ide.$scope.$broadcast 'reload-output-files'
						$scope.state.inflight = false
						$modalInstance.close()

			$scope.cancel = () ->
				$modalInstance.dismiss('cancel')
	]
