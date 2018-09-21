# IsoBuilder

Ideový nástin, jak udělat automatické vyrábění zapatchovaných ISO s Windows 2016.
V kódu jsou navrrdo některé cesty (YOURURL, YOURBUCKET), je třeba je vyměnit.

Ukázka k webináři https://youtu.be/8_1218pHBJo

* isobuilder.ps1 - sestavuje ISO. Stáhne si z netu golden image
* DownloadLatestIso.ps1 - stáhne z netu (S3) poslední image (nemusí být na stejním místě jako tam, kde se buildí)
* SetupAWS.ps1.example - smažte příponu .example a zadejte své AWS credentials. Spusťte jednou na serveru, odkud se hotové image uploadují.
* SyncIsoToS3.ps1 - uploaduje poslední isO, pokud ještě není na netu.
