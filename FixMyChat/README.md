# FixMyChat
> Send chat messages in Cyrillic/Hieroglyphics without need to use Latin characters.

This plugin is used for **fix an issue** where player tries to send a message in chat using only non-latin characters and finds that it wasn't sent and just disappeared.

**In original Sven Co-op**, there is solution where you add one latin character *(also it can be ./!/- and other standard symbols)* to your message and it will be successfuly sent, but it's awkward and thereby wasting your precious time ( 'д' )

## How it works

Plugin parses your message and compares its length in ASCII and UTF-8 encodings, if it's not equal - game resends your fixed message to the server.

## Showcase

