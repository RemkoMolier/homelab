# src/inspect.py
import os
import json
from pathlib import Path
from dockerfile_parse import DockerfileParser
from github_custom_actions import ActionBase,ActionInputs,ActionOutputs

class MyInputs(ActionInputs):
    dockerfile: str
    '''Dockerfile to be inspected'''
    prefix: str
    '''Prefix for application, to be used to determine version'''

class MyOutputs(ActionOutputs):
    base_image: str
    '''Base image for the final image build'''
    build_args: str
    '''JSON structure containing the build arguments and their default values'''
    labels:str
    '''JSON structure containing the labels and their values'''
    version:str
    '''Application version, if defined as a build argument'''

class MyAction(ActionBase):
    inputs: MyInputs
    outputs: MyOutputs

    def main(self):
        if self.inputs.dockerfile is not None:

            if not os.path.isfile(self.inputs.dockerfile):
                raise ValueError("dockerfile {} can not be accessed".format(self.inputs.dockerfile))

            # Try to parse the dockerfile
            try:
                dfp = DockerfileParser(path=self.inputs.dockerfile,cache_content=True)
            except Exception as error:
                raise error

            # Output the default values
            self.outputs.base_image = dfp.baseimage
            self.outputs.build_args = json.dumps(dfp.args,separators=(',', ':'),sort_keys=True)

            # Prepare the labels
            labels = ""
            for key, value in dfp.labels.items():
                labels += '{}={}\n'.format(key,value)
            self.outputs.labels = labels

            # See if a version identifier can be found
            if self.inputs.prefix is not None:
                index = self.inputs.prefix.upper() + "_VERSION"
                if index in dfp.args:
                    self.outputs.version = dfp.args[index]
            elif "VERSION" in dfp.args:
                self.outputs.version = dfp.args["VERSION"]

        else:
            raise ValueError("dockerfile is required")


if __name__ == "__main__":
    MyAction().run()
