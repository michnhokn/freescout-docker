## Instructions

1. Get image from ghcr registry `ghcr.io/michnhokn/freescout-docker:latest`
2. Set environment variables (See `.env.example` for reference)
3. Start container `docker run -d --name freescout -p 8080:80 --env-file .env ghcr.io/michnhokn/freescout-docker:latest`
4. Access the application and create a user `php artisan freescout:create-user`
5. Set up message worker via scheduler `php artisan schedule:run` every minute `* * * * *`
6. Enjoy!