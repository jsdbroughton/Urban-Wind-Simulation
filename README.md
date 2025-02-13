# Introduction

**Urban Wind Simulation** is a Speckle Automate function that aims to solve wind comfort levels on an urban scale by using computational fluid dynamics with OpenFOAM 11. The base libraries behind it are [archaea-simulation](https://pypi.org/project/archaea-simulation/) and [archaea](https://pypi.org/project/archaea/), which include interfaces to convert given geometries into CFD scenarios.

![CFD Sample Result](https://github.com/user-attachments/assets/b8379459-ce42-4078-880f-cc39ee02074c)

# Key Concepts

## 1. Domain Orientation

In urban wind simulation, the proper orientation of the computational domain is crucial for accurately assessing wind effects on urban environments. The domain orientation is typically defined in relation to the prevailing wind direction. This relationship ensures that the simulated wind flow aligns with the real-world wind conditions and enables the precise modelling of urban airflow.

The direction of the wind is commonly represented using meteorological angles (δ), designated as δ. These angles increase clockwise from the north (y) axis. In this convention, 0 degrees typically points to the north, 90 degrees points to the east, 180 degrees points to the south, and 270 degrees points to the west. Meteorological conventions are widely used in weather and wind studies, making it essential to align the domain orientation with these angles. Math angles, designated by α, increase counterclockwise from the east (x) axis. The user needs to define wind direction from meteorological angles for OpenFOAM simulations.

![Math & Meteo Angles](https://github.com/user-attachments/assets/a85b12cd-8fcd-4870-93c8-e31abc687445)


## 2. Atmospheric Boundary Layer (WIP)

Wind speed data collected from weather stations provides precise values for specific heights. However, when simulating wind behaviour at varying altitudes, creating an atmospheric boundary layer (ABL) is not just a recommended practice; it's an absolute necessity.

Weather stations typically provide wind data at specific heights above the ground. These measurements offer valuable insights into the wind's behaviour but are limited to the measured heights. In urban environments, wind patterns vary significantly with altitude due to the influence of buildings, terrain, and other factors. Simulating the ABL is essential to accurately represent real-world conditions because it accounts for the vertical variation in wind speed, turbulence, and other atmospheric parameters.

![Atmospheric Boundary Layer](https://github.com/user-attachments/assets/b1eaa43a-7ac5-4a3b-8672-a315ae2dc092)


## 3. Wind Tunnel Sizing

A wind tunnel serves as the designated domain where air flows during simulations. The automation function is crucial in determining the bounding box's alignment with the wind direction for geometries targeted for simulation. It then scales the computational domain according to the specified function inputs. The domain's size is a critical factor in wind simulations, as it directly impacts various aspects, including simulation time and the number of volume meshes.

#### Realistic Wind Tunnel Simulations

Wind tunnels are essential for accurately modelling wind flow around complex geometries, such as buildings or structures. They provide a controlled environment where the effects of wind can be studied, enabling engineers and researchers to gain insights into aerodynamic behaviour, pressure distributions, and other critical parameters. Wind tunnels ensure that simulations closely match real-world conditions.

#### Automated Alignment and Scaling

The automated bounding box alignment and domain scaling function simplifies and streamlines the simulation process. It ensures the domain is appropriately aligned with the prevailing wind direction for the specific geometry under study. Automating these tasks reduces the potential for errors and makes it easier to adapt simulations to different scenarios and geometries.

#### Impact on Simulation Time

The size of the computational domain directly impacts the time required for wind simulations. Larger domains encompass more grid points and computational elements, which can significantly increase computational demands. Understanding this relationship is crucial for optimizing simulation efficiency, as vast domains may lead to impractical computation times, while overly small domains may sacrifice accuracy.

#### Meshing Considerations

In wind simulations, the number of volume meshes generated is closely tied to the domain's size. Larger domains with finer resolution require more mesh elements, increasing computational and memory requirements. Balancing domain size and mesh density is critical for achieving accurate results while maintaining computational feasibility.

![Wind Tunnel Sizing](https://github.com/user-attachments/assets/2f36426a-64ee-4b1d-a836-ee37d99668d2)

## 4. Parallel Computing

OpenFOAM supports parallelism through domain decomposition, which divides the computational domain into smaller subdomains that can be solved concurrently. This approach efficiently distributes computational work, reduces simulation times, and enables the modelling of larger and more complex problems.

#### Efficient Computational Work Distribution

Domain decomposition is a fundamental technique that optimizes the distribution of computational work among multiple processing units (cores or nodes). By breaking the domain into smaller, manageable subdomains, a separate processor can solve each subdomain independently. This efficient distribution of work enables parallel processing, significantly reducing simulation times for complex problems.

#### Scalability and Complex Problem Solving

OpenFOAM's support for domain decomposition makes it highly scalable. It allows simulations to be scaled up to handle larger and more intricate problems, whether in terms of domain size, mesh complexity, or the number of simulated physical processes. This scalability is especially critical in urban-scale modelling, where simulations often involve complex geometries and extensive meshing.

#### Resource Utilization
Effectively utilizing parallelism with domain decomposition is vital for maximizing computational resource utilization. It enables simulations to fully take advantage of multi-core processors or distributed computing clusters, which is essential for completing simulations in a reasonable amount of time, particularly for urban-scale studies with significant computational requirements.

#### Simulating Real-World Complexities
In urban wind simulations, various factors come into play, including the presence of buildings, streets, and other urban features that influence wind patterns. OpenFOAM's parallelism with domain decomposition empowers researchers to simulate these real-world complexities with the accuracy and efficiency required for urban planning, environmental assessments, and urban microclimate studies.

#### Handling Large Data Sets
Urban-scale simulations often generate extensive data sets for analysis. Parallelism allows simulations to efficiently handle and process the large volumes of data generated, ensuring researchers can extract valuable insights from the simulations promptly.

## 5. Supported Speckle Objects

- Objects.Geometry.Brep
