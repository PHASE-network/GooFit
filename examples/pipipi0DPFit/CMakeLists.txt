

set(DATA_FILE "${CMAKE_CURRENT_SOURCE_DIR}/alltxtfiles4pipipi0DPFit.tgz")

if(NOT EXISTS ${DATA_FILE})
file(DOWNLOAD
    https://github.com/GooFit/GooFit/releases/download/v1.0.0/alltxtfiles4pipipi0DPFit.tgz
    ${DATA_FILE}
    SHOW_PROGRESS
    EXPECTED_HASH SHA256=7c1a2ad656772d31fee9f6a43590e47574c9bdc32afce820820f30efca13803d
    )
endif()

if(NOT EXISTS 
        "${CMAKE_CURRENT_SOURCE_DIR}/signal_sigma_2slices_pdf.txt"
        )
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xzf ${DATA_FILE}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
endif()


goofit_add_executable(pipipi0DPFit pipipi0DPFit.cu)
goofit_add_directory()
