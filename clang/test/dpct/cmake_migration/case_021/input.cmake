add_compile_options(-std=c++11)
add_compile_options(-std=c++14)
add_compile_options(-std=c++17)

#Currently we use Yaml based migartion rule to migarte -std=c++22 down to -std=c++17.
#We will implement an implicit migration rule to fix this issue in future.
#add_compile_options(-std=c++22)
