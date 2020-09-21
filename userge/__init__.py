# pylint: disable=missing-module-docstring
#
# Copyright (C) 2020 by DarkWebAze@Github, < https://github.com/DarkWebAze >.
#
# This file is part of < https://github.com/DarkWebAze/DarkUserBot > project,
# and is released under the "GNU v3.0 License Agreement".
# Please see < https://github.com/DarkWebAze/DarkUserBot/blob/master/LICENSE >
#
# All rights reserved.

from dark.logger import logging  # noqa
from dark.config import Config, get_version  # noqa
from dark.core import (  # noqa
    Dark, filters, Message, get_collection, pool)
dark = Dark()  # dark is the client name
