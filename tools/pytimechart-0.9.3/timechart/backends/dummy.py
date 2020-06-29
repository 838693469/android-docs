def get_partial_text(fn,start,end):
    return ""
def load_dummy(fn):
    from timechart.model import tcProject
    proj = tcProject()
    proj.filename = fn
    proj.start_parsing(get_partial_text)
    proj.finish_parsing()
    return proj


def detect_dummy(fn):
    #todo
    return load_dummy
