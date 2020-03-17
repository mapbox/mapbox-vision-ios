# Contributing

Everyone is invited to participate in Mapbox's open source projects and public discussions: we want to create a welcoming and friendly environment.

## Before you start

### Dev envrionment setup

<details>
<summary>Secret-shield setup</summary>
<p>

We use [secret-shield](https://github.com/mapbox/secret-shield) tool which runs as a pre-commit hook. In order to enable it you should install it with:
```sh
npm install -g @mapbox/secret-shield
```

Then you have to add a pre-commit git hook. The simplest option is to copy the following script into a `mapbox-vision-ios/.git/hooks/pre-commit`:
```sh
#!/bin/sh
secret-shield --pre-commit -C verydeep --enable "Mapbox Public Key" --disable "High-entropy base64 string" "Short high-entropy string" "Long high-entropy string"
```

Don't forget to make it executable:
```sh
chmod +x .git/hooks/pre-commit
```

As an option you can integrate hook via git hooks manager (like [Husky](https://github.com/typicode/husky) or [Komondor](https://github.com/shibapm/Komondor)).
More information about installation is available [here](https://github.com/mapbox/secret-shield#install).

</p>
</details>

## Code of conduct

### Our Standarts

Harrassment of participants or other unethical and unprofessional behavior will not be tolerated in our spaces.

Examples of behavior that contributes to creating a positive environment include:
- Using welcoming and inclusive language.
- Being respectful of differing viewpoints and experiences.
- Gracefully accepting constructive criticism.
- Focusing on what is best for the community.
- Showing empathy towards other community members.

The [Contributor Covenant](https://www.contributor-covenant.org) applies to all projects under the Mapbox organization whether they explicitly include the Contributor Covenant's [CODE_OF_CONDUCT.md](https://www.contributor-covenant.org/version/1/4/code-of-conduct.html) or not.

### Writing a Pull Request

We recommend to read [blog post from Github](https://github.blog/2015-01-21-how-to-write-the-perfect-pull-request/).

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on repository](https://github.com/mapbox/mapbox-vision-ios/tags).

Changes in repository is in sync with changes in `Vision Core` library (which is under-the-hood of Vision SDK).
