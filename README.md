## Instructions

1. Get image from ghcr registry `ghcr.io/michnhokn/freescout-docker:latest`
2. Set environment variables (See `.env.example` for reference)
3. Start container `docker run -d --name freescout -p 8080:80 --env-file .env ghcr.io/michnhokn/freescout-docker:latest`
4. Access the application and create a user `php artisan freescout:create-user`
5. Set up message worker via scheduler `php artisan schedule:run` every minute `* * * * *`
6. Enjoy!

## Known Issues

- After a restart of a container, the js assets are broken. To fix you have to navigate to `/system/tools` and clear the
  cache. Afterward visit the `/system/status` page to trigger the asset rebuild. This is a known issue and will be
  fixed in a future release.