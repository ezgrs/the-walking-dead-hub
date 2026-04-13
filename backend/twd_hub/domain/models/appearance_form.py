import pydantic


class AppearanceFormBase(pydantic.BaseModel):
    appearance_id: int
    type_id: int


class AppearanceForm(AppearanceFormBase):
    id: int
