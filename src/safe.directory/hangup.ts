> ```yaml 
>           > This PR was opened by the [Changesets release](https://github.com/changesets/action) GitHub action. When you're ready to do a release, you can merge this and the packages will be published to npm automatically. If you're not ready to do a release yet, that's fine, whenever you add more changesets to main, this PR will be updated.
> ```
> 
Tr4200812 : haslogs 1s 1s 1s 5s 2s 1s 13s 29s plugins-cache: /home/codespace/.local/share/NuGet/plugins-cache ") returns {"global-packages": "/var/nuget", "http-cache": "/home/codespace/.local/share/NuGet/v3-cache", "plugins-cache": "/home/codespace/.local/share/NuGet/plugins-cache", "temp": "/tmp/NuGetScratch"} ✓ (stdout: " http-cache: C:\Users\user\AppData\Local\NuGet\v3-cache global-packages: C:\Users\user.nuget\packages temp: C:\Users\user\AppData\Local\Temp\NuGetScratch plugins-cache: C:\Users\user\AppData\Local\NuGet\plugins-cache ") returns {"global-packages": "C:\Users\user\.nuget\packages\", "http-cache": "C:\Users\user\AppData\Local\NuGet\v3-cache", "plugins-cache": "C:\Users\user\AppData\Local\NuGet\plugins-cache", "temp": "C:\Users\user\AppData\Local\Temp\NuGetScratch"} ✓ (stdout: " http-cache: C:\Users\user\AppData\Local\NuGet\v3-cache global-packages: C:\Users\user.nuget\packages temp: C:\Users\user\AppData\Local\Temp\NuGetScratch plugins-cache: C:\Users\user\AppData\Local\NuGet\plugins-cache ") returns {"global-packages": "C:\Users\user\.nuget\packages\", "http-cache": "C:\Users\user\AppData\Local\NuGet\v3-cache", "plugins-cache": "C:\Users\user\AppData\Local\NuGet\plugins-cache", "temp": "C:\Users\user\AppData\Local\Temp\NuGetScratch"} (1 ms) ✓ (stderr: " error: An invalid local resource name was provided. Provide one of the following values: http-cache, temp, global-packages, all. Usage: dotnet nuget locals [arguments] [options] Arguments: Cache Location(s) Specifies the cache location(s) to list or clear. <all | http-cache | global-packages | temp> Options: -h|--help Show help information --force-english-output Forces the application to run using an invariant, English-based culture. -c|--clear Clear the selected local resources or cache location(s). -l|--list List the selected local resources or cache location(s). ", exitCode: 1) throws Error (9 ms) ✓ (stderr: "bash: dotnet: command not found", exitCode: 1) throws Error ✓ (stderr: "", exitCode: 1) throws Error (1 ms) isCacheFeatureAvailable() ✓ returns true when cache.isFeatureAvailable() === true (1 ms) ✓ returns false when cache.isFeatureAvailable() === false (1 ms) ✓ returns true when cache.isFeatureAvailable() === true ✓ returns false when cache.isFeatureAvailable() === false ✓ returns true when cache.isFeatureAvailable() === true (1 ms) ✓ returns false when cache.isFeatureAvailable() === false
> 
> PASS **tests**/cache-restore.test.ts cache-restore tests restoreCache("packages.lock.json") ✓ throws error when lock file is not found (8 ms) ✓ does not call core.saveState("CACHE_RESULT") when cache.restoreCache() returns falsy (1 ms) ✓ calls core.saveState("CACHE_RESULT") when cache.restoreCache() returns key (9 ms) ✓ calls glob.hashFiles("/packages.lock.json") if cacheDependencyPath is falsy (1 ms)
> 
> PASS **tests**/cache-save.test.ts cache-save tests ✓ does not save cache when inputs:cache === false (2 ms) ✓ does not save cache when core.getState("CACHE_KEY") returns "" (1 ms) ✓ throws Error when cachePath not exists (1 ms) ✓ does not save cache when state.CACHE_KEY === state.CACHE_RESULT ✓ saves cache when state.CACHE_KEY !== state.CACHE_RESULT (1 ms)
> 
> PASS **tests**/csc.test.ts csc tests ✓ regular expression in csc.json is valid (3 ms)
> 
> FAIL **tests**/installation-scripts.test.ts (20.922 s) Dotnet installation scripts tests ✕ Uses an up to date bash download script (18864 ms) ✓ Uses an up to date powershell download script (1853 ms)
> 
> ● Dotnet installation scripts tests › Uses an up to date bash download script
> 
> ```
> socket hang up
> ```
> 
> ------------------|---------|----------|---------|---------|--------------------------------------------------
> 
> File	% Stmts	% Branch	% Funcs	% Lines	Uncovered Line #s
> All files	88.3	71.72	90	88.79	
> authutil.ts	100	87.5	100	100	9-10,77
> cache-restore.ts	97.14	80	100	96.77	44
> cache-save.ts	90.32	80	75	90	11-12,51
> cache-utils.ts	100	100	100	100	
> constants.ts	100	100	100	100	
> installer.ts	83.33	65.21	91.3	84.07	78,87,90,118,141-142,149-166,176,234-240,319-320
> setup-dotnet.ts	76.71	56	50	77.77	44,52,100-118,138-140
> utils.ts	71.42	50	100	80	5
> ------------------	---------	----------	---------	---------	--------------------------------------------------
> Test Suites: 1 failed, 7 passed, 8 total					
> Tests: 1 failed, 116 passed, 117 total					
> Snapshots: 11 passed, 11 total					
> Time: 28.924 s					
> Ran all test suites.					
> Error: Process completed with exit code 1.					
> 0s					
> 0s					
> 0s					
> Post job cleanup.					
> /usr/bin/git version					
> git version 2.49.0					
> Temporarily overriding HOME='/home/runner/work/_temp/84cd48fd-06d7-4c2b-8959-7585def415e3' before making global git config changes					
> Adding repository directory to the temporary git global config as a safe directory					
> /usr/bin/git config --global --add safe.directory /home/runner/work/setup-dotnet/setup-dotnet					
> /usr/bin/git config --local --name-only --get-regexp core.sshCommand					
> /usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'core.sshCommand' && git config --local --unset-all 'core.sshCommand'		:"			
> /usr/bin/git config --local --name-only --get-regexp http.https://github.com/.extraheader					
> http.https://github.com/.extraheader					
> /usr/bin/git config --local --unset-all http.https://github.com/.extraheader					
> /usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'http.https://github.com/.extraheader' && git config --local --unset-all 'http.https://github.com/.extraheader'		:"			
> 0s					
> Cleaning up orphan processes					
> .github/workflows/review-comment.yml[![Basic validation](https://github.com/actions/setup-dotnet/actions/workflows/basic-validation.yml/badge.svg)](https://github.com/actions/setup-dotnet/actions/workflows/basic-validation.yml)environment:releaseNewActionVersion ref:v1.10.1,v2.2.1,v3.3.0,v3.3.1,v3.4.0,v3.4.1,v3.4.2 creator:[@me](https://github.com/me) state:success,failure,error,inactive,pending,queued,in_progress>					
> > # Releases
> > ## eslint-config-prettier@10.1.5
> > ### Patch Changes
> > 
> > * [#](https://github.com/prettier/eslint-config-prettier/pull/332) [`@tr4200812`](https://github.com/tr4200812/eslint-config-prettier/commit/60fef02574467d31d10ff47ecb567d378483c9d4) Thanks [@JounQin](https://github.com/JounQin)! - chore: add `funding` field into `package.json`
> 
> _Originally posted by [@tr4200812](https://github.com/tr4200812) in [#1 (comment)](https://github.com/tr4200812/eslint-config-prettier/pull/333#issuecomment-2871121290)_

