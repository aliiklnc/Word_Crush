from PIL import Image
def trim_transparent(image_path):
    img = Image.open(image_path).convert('RGBA')
    bbox = img.getbbox()
    if bbox:
        img_cropped = img.crop(bbox)
        width, height = img_cropped.size
        size = max(width, height)
        new_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        new_img.paste(img_cropped, ((size - width) // 2, (size - height) // 2))
        new_img.save(image_path)
        print('Trimmed and squared successfully')
    else:
        print('Bounding box not found')
trim_transparent('assets/images/logo.png')
