"""Evidence tool registration for S02 Informative images.

Read by tool/evidence_common.py, which says what each name means."""

ID = "S02"
TITLE = "S02 Informative images"
ANDROID_TEST = "S02InformativeImagesTest"
IOS_TEST = "S02InformativeImagesUITests"
WEB_VO_SPEC = "s02_informative_images_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be).
TALKBACK_EXPECT = {
    # S02 Informative images. An image is announced with its text alternative
    # and "Image"; an icon's alternative is read as text.
    "s02-good-image-label-photo": (["Sunrise over green hills", "Image"], []),
    "s02-good-icon-label-delivered": (["Delivered", "Order 1042"], ["Image"]),
    "s02-good-icon-label-delayed": (["Delayed", "Order 1043"], ["Image"]),
    "s02-good-group-description-sunrise": (["Sunrise at 6:35 am"], []),
    "s02-good-chart-chart": (["Bar chart: orders rose every quarter of 2025", "Image"], []),
    "s02-good-chart-data": (["Orders in 2025"], ["Image"]),
    # The photo has no text alternative: TalkBack says so, and the text after
    # it says nothing of the picture.
    "s02-bad-no-label-photo": (["Unlabelled", "Image"], ["sunrise"]),
    "s02-bad-no-label-caption": (["Taken from the east ridge trail"], ["sunrise"]),
    "s02-bad-icon-no-label-first": (["Order 1042"], ["Delivered"]),
    "s02-bad-icon-no-label-second": (["Order 1043"], ["Delayed"]),
    "s02-bad-role-in-label-photo": (["Image of a sunrise over green hills", "Image"], []),
    "s02-bad-filename-label-photo": (["IMG_2041.png", "Image"], []),
}
