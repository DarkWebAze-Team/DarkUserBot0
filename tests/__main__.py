# pylint: disable=missing-module-docstring
#
# Copyright (C) 2020 by DarkWebAze@Github, < https://github.com/DarkWebAze >.
#
# This file is part of < https://github.com/DarkWebAze/DarkUserBot > project,
# and is released under the "GNU v3.0 License Agreement".
# Please see < https://github.com/DarkWebAze/DarkUserBot/blob/master/LICENSE >
#
# All rights reserved.

import os

from userge import dark


async def worker() -> None:  # pylint: disable=missing-function-docstring
    chat_id = int(os.environ.get("CHAT_ID") or 0)
    await dark.send_message(chat_id, '`build completed !`')

if __name__ == "__main__":
    dark.begin(worker())
    print('dark test has been finished!')
