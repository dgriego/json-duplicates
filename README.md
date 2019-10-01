# Setup for running the script

## Setup Ruby Environment

The Ruby version is specified in the .ruby-version file. I use `rbenv` to
configure the ruby version on my system, but you can use either `rvm` or `rbenv` to
set the correct ruby version for this script.

If you don't have either install, you can install `rbenv` [here](https://github.com/rbenv/rbenv#installation)

## Setup and run script

After the `ruby` version has been set, follow these steps to run the script:

from the root of the repo:

1. fork and clone the repo
2. `cd json-duplicates`
3. `gem install bundler`
4. `bundle install`
5. `./sanitize_leads`

## When the script is run, it will produce the following results:

- Output valid lead count, duplicate lead count, and a column-row representation
  of the valid leads
- Output the valid leads as json into a generated file labeled "valid-leads"
  with a timestamp
- finally, it will create an entry in the change_log.txt file with a representation
  of the input (before) and output (after)
