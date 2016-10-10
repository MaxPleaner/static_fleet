### What does this do?

Are you keen on static site generators built with Ruby such as [gollum](https://github.com/gollum/gollum), [jekyll](http://jekyllrb.com),
[middleman](https://middlemanapp.com), or [nanoc](http://nanoc.ws/)?

Do you wish they they had web interfaces for editing the source code?

Do you wish they handled deploys for you?

_If so, you're in luck_.

There are four kinds of websites this can create:

1. Built using [static](http://github.com/maxpleaner/static). This framework is designed to create a responsive, filterable grid containing pages written in markdown. Will compile slim/sass/coffeescript. See that README for more info. 
  - If this framework is chosen, the 'scripts' section has some available helpers to assist with creating pages

      ```
        unsaved_page = Page.new(
          "name of the page",
          "## markdown content of the page",
          ["tags", "list", "to", "inform", "grid", "filtering"]
        )
        Page.save([unsaved_page], "the-site-name-to-save-to")
      ```
  - `Page.save` will create a markdown file in `<app_name>/source/markdown`
2. Built with an empty directory, configured to serve plain html/css/js as-is (no precompilation will occur)
3. Built by uploading a zip file containing plain html/css/js. This will be served as-is (no precompilation will occur)
4. Built using [genrb](http://github.com/maxpleaner/genrb). The source dir will initially be empty, and will compile slim/sass/coffeescript. See that README for more info. 

_note_: to be clear, when I say "sass", I mean the `.sass` extension and syntax, not that of `.scss`. Cofeescript files have a `.coffee` extension and slim files will have a `.slim` extension. 

### Setup

1. Install ruby 2.3 or newer
2. run `git clone http://github.com/maxpleaner/static_fleet`
3. `cd static_fleet`
4. run `git clone http://github.com/maxpleaner/static static_site_skeleton`
3. Run `bundle install`. You might have to install some system dependencies for this to succeed.
4. Install `awscli` using `pip`. Run `aws configure` and enter your credentials and region.
  - _note_ you should be using credentials for an IAM user with an administrator role, not the master AWS account
5. add a line `signature_version = s3v4` to `~/.aws/config`. You can see `aws_config.example` as a template.
5. Install `rsync` and `unzip`, which are used to upload / deploy generic static sites
5. Rename [.env.example](./.env.example) to `.env`. Edit the file with the following env vars:
  - `AWS_ACCESS_TOKEN_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION`
  - `STATIC_FLEET_USERNAME` (your selected username for logging in to _static fleet_)
  - `STATIC_FLEET_PASSWORD` (your selected password for logging into _static fleet_)
6. Note that `.env` is in `.gitignore`, so if you deploy you'll have to fill in `.env` again on the production machine.
6. `bundle exec rackup` to start the site on port 9292

### Using the web interface

1. Visit `localhost:9292`
2. Login using your specified `STATIC_FLEET_USERNAME` and `STATIC_FLEET_PASSWORD`
3. Scroll down to the "Create site" section.
  - Choose which type of site should be created
  - Enter a name for the website / s3 bucket. It must be completely unique on S3, i.e. something generic like `test` won't work. Any character that is not alphaneumeric or a dash will be changed to a dash. 
  - Press `submit` to create a S3 bucket configured to serve a static website.
4. Scroll down to "Sites list" and click the name of the newly created site.
  - Observe the file / directory listing.
  - Click a folder to explore, or click a file to see it's contents and edit it.
  - Click add/remove files to see options to create/delete/upload files. 
6. Deploy
  - Click the name of the site you want to deploy from the "Sites list" section
  - Click build.
  - Click deploy.
  - Visit the website at `http://MY_CUSTOM_SITENAME.s3-website-us-east-1.amazonaws.com
    - if you've changed the `AWS_REGION`, the url will be slightly different
7. Use the "scripts" section
  - this allows writing arbitrary ruby scripts, saving them to the database as strings, and invoking them when called upon.
  - The `@data` instance variable can be considered the "return value" of a script, and after a script is run, its value will be displayed. The `@data`  value will be passed along to subsequently run scripts
  - i.e. one script could load `@data` with some text corpus, and other script could reference these texts via `@data`.
  - The different categories of scripts ("data", "page", "arbitrary") all work the same way. The difference is purely semantic and is intended to reflect the intention of the script. 
  - Note that it is possible to wreck havok on the underlying system using the "scripts" feature, which is why this app is intended to be single-user only. 

### Deploying

This app requires a persistent write-enabled filesystem.

This is generally considered insecure for public-facing sites, but this app is designed for a single-user only so it is not risky unless the master password is shared.

Because of this requirement, it will not work on Heroku.

At the moment I'm deploying mine using Linode using a very simple `ngrok` + `screen` setup.

I'm sure tons of other hosts will work as well.

---

_Thanks and contribute_
