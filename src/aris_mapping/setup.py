from setuptools import setup

package_name = "aris_mapping"

setup(
    name=package_name,
    version="0.1.0",
    packages=[package_name],
    data_files=[
        ("share/ament_index/resource_index/packages", [f"resource/{package_name}"]),
        (f"share/{package_name}", ["package.xml"]),
    ],
    install_requires=["setuptools"],
    zip_safe=True,
    maintainer="ARIS",
    maintainer_email="aris@example.invalid",
    description="Semantic HD map cores for ARIS V3 simulation scaffolding.",
    license="Apache-2.0",
    tests_require=["pytest"],
)
