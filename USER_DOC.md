# 42-Inception - User Documentation

This document explains how to use and manage the website deployed by the Inception project from an end-user or administrator perspective. It focuses on the available services, how to access the website, manage users, and verify that the platform is working correctly.  

## Table of Contents

- [Services provided by the stack](#services-provided-by-the-stack)
  - [Components involved](#components-involved)
- [Start and stop the project](#start-and-stop-the-project)
  - [Start the project](#start-the-project)
  - [Stop and clean](#stop-and-clean)
- [Access the website and the administrator panel](#access-the-website-and-the-administrator-panel)
  - [Access the website](access-the-website)
  - [Access the administrator panel](#access-the-administrator-panel)
  - [Administrator dashboard overview](#administrator-panel-overview)
- [Locate and manage credentials](locate-and-manage-credentials)
  - [Administrator and user roles](#administrator-and-user-roles)
  - [Managing users from the admin panel](#managing-users-from-the-admin-panel)
- [Check that the services are running correctly](check-that-the-services-are-running-correctly)
  - [Website accessibility](#website-accessibility)
  - [Administrator login](#administrator-login)
  - [Content creation](#content-creation)
- [What can you do with the website](#what-can-you-do-with-the-website)
  - [Create a post](#create-a-post)
  - [Upload media files](#upload-media-files)
  - [Manage users](#manage-users)
  - [Create and edit pages](#create-and-edit-pages)
  - [Install themes](#install-themes)
  - [Install plugins](#install-plugins)

-------------------------------------------------

## Services provided by the stack
The *Inception* stack deploys a complete WordPress website accessible through a secure HTTPS connection.  
The platform provides the following services:  
- WordPress website accesible via HTTP
- WordPress administration dashboard (`/wp-admin`)
- User authentification system
- Role-based permission management
- Content creation (posts and pages)
- Media upload and management
- Persistent storage of website data  

### Components involved
The platform relies on three services:
- **NGINX** - handles HTTP access and serves web requests
- **WordPress (PHP-FPM)** - provides the website interface and application logic
- **MariaDB** - stores users, posts, and configuration data

All user data persist even if the services are restarted.  

## Start and stop the project
### Start the project
Run: 

         make
         
This command:
- builds the bind mount directories. Requires sudo to set correct permissions for mariadb
- builds the Docker images (if needed)
- starts all services
- deploys the website automatically

### Stop and clean
| Command | Effect |
|---|---|
|  `make stop`| Stops containers without removing them |
| `make down` | Stops and removes containers and networks, keeps persistent data |
| `make clean`| Removes containers, images, and network but preserves persistent data |
| `make fclean` | Fully rests the project, including persitent website data |
     
## Access the website and the administrator panel

### Access the website
Since the project runs inside a virtual machine, SSH tunneling or proxy configuration is required. For details, see: [Domain configuration ad SSH tunneling](./DEV_DOC.md#domain-configuration-and-ssh-tunneling).  
Open a browser and navigate to:  

         https://<login>.42.fr

The website should load using HTTPS.

### Access the administrator panel
Open:  

      https://<login>.42.fr/wp-admin

### Administrator dashboard overview
The WordPres administrator dashboard allows full website management.  
Main available actions:
- Create and publish posts
- Create and edit pages
- Upload media files
- Manage users and roles
- Install and activate themes
- Install plugins
- Configure website settings


## Locate and manage credentials
This section explains where the WordPress credentials are defined, how they are used to access the website, and how users and roles can be managed from the WordPress administration interface.  

### WordPress access credentials
The initial WordPress credentials are defined at deployment time. Usernames are defined through environment variables in the `.env` file, while passwords are securely provided through Docker secrets and injected at container runtime.  
For implementation details, see: 
- [Environment variables](./DEV_DOC.md#environment-variables-env-file)
- [Docker secrets configuration](./DEV_DOC#secrets))
   
The following credentials are created automatically when the stack is deployed:  

         WORDPRESS_ADMIN_USER
         WORDPRESS_USER

Passwords are store in Docker secrets: 
         wp_admin_password
         wp_user_password

These credentials are used to access the WordPress website and the administration panel.  
- Administrator credentials:
  - Used to access the WordPress admin dashboard at `/wp-admin`
  - Full control over the website
- Standard user credentials
  - Used to log in as a non-administrator user
  - Limited permissions depending on the assigned role

Once WordPress is installed, these users are stored internally by WordPress and persist accross container restarts.  

### Administrator and user roles
WordPress uses a role-based permission system.  
Each user account is assigned exactly one role, which defines what actions the user is allowed to perform.  
The default WordPress roles are:
- **Administrator**: full control over the website
- **Editor**: manages all posts and pages
- **Author**: publishes and manages own posts
- **Contributor**: writes posts but cannit publish
- **Subscriber**: manages only their profile

In this project, WordPress is initially deployed with:
- one administrator account
- one standard user account with limited permissions

### Managing users from the admin panel
User and role maangement is done directly from the WordPress administration interface.  
To manage users:
1. Log in as administrator at:

            https://<login>.42.fr/wp-admin

2. Navigate to:

         Users -> All Users

3. Select a user
4. Change the assigned role using the Role dropdown
5. Save changes

Role changes take effect immediately and define what actions the user can perform on the website.  

## Check that services are running correctly
The following tests verify that the entire platform operates correctly.

### Website accessibility

1. Open a browser
2. Navigate to:


                 https://<login>.42.fr
     
3. Expected result: 
  - Website loads successfully
  - Conection uses HTTPS

### Administrator login

1. Open

             https://<login>.42.fr/wp-admin
     
2. Enter administrator credentials
3. Expected result:
   - Access to WordPress dashboard

### Content creation
1. Dashboard -> Posts -> Add New
2. Create a test post
3. CLock **Publish**
4. Visit the homepage
5. Expected result:
   - Post appears publicily

## What can you do with the website
### Create a post
1. Log in as administrator
2. Navigate to: Post-> Add New
3. Write a title and content
4. Clock **Publish**  
The post becomes visible on the homepage.

### Upload media files
1. Dashboard -> Media -> Add New
2. Upload an image
3. Insert it into a post or page  
Uploaded files are stored persistently.

### Manage users
1. Dashboard -> Users -> All Users
2. Add or edit users
3. Assign roles using the Role selector  
Changes apply inmediately.

### Create and edit pages
1. Pages -> Add New
2. Create a static content (About, Contact, etc.)
3. Publish the page

### Install themes
1. Appearance -> Themes
2. Add New
3. Activate a theme
The website appearance updates instantly.

### Install plugins
1. Plugins -> Add New
2. Install a plugin
3. Activate it
Plugins extend website functionality.  

