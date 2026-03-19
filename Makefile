.PHONY: deploy sync-locale
deploy:
	git checkout main
	git merge dev
	git push origin main
	git checkout dev

sync-locale:
	cp skill-package/interactionModels/custom/en-US.json skill-package/interactionModels/custom/en-GB.json
	cp skill-package/interactionModels/custom/en-US.json skill-package/interactionModels/custom/en-IN.json