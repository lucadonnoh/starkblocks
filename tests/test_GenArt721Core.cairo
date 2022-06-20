%lang starknet
from src.GenArt721Core import nextProjectId, addProject, Project, projects, getNextProjectId, addProjectScript, getProjectScript, mint, getInvocations, getTokenHash
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2

const ONE_MILLION = 1000000

@view
func test_deploy{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    let (id) = nextProjectId.read()
    assert id = 1
    return ()
end

@view
func test_create_project{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    let (id) = addProject(Project('planets', 0xB0B, 100, 0))
    assert id = 1
    let (project : Project) = projects.read(id)
    assert project.name = 'planets'
    assert project.artist = 0xB0B
    assert project.maxInvocations = 100
    assert project.paused = 0
    let (nextId) = getNextProjectId()
    assert nextId = 2
    return ()
end

@view
func test_add_project_script{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    let (id) = addProject(Project('planets', 0xB0B, 100, 0))
    let (pre_script) = getProjectScript(1)
    assert pre_script = 0
    assert id = 1
    addProjectScript(id, 69420)
    let (post_script) = getProjectScript(1)
    assert post_script = 69420
    return ()
end

@view
func test_mint_one{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    local bea_address : felt
    %{ ids.bea_address = deploy_contract("./lib/cairo_contracts/src/openzeppelin/account/Account.cairo", [69]).contract_address %}
    let (id) = addProject(Project('planets', 0xB0B, 100, 0))

    let (pre_invocations) = getInvocations(id)
    assert pre_invocations = 0
    let (token_hash_to_be) = hash2{hash_ptr=pedersen_ptr}(69, 420)

    let to = bea_address
    %{ expect_events({"name": "Mint", "data":[ids.bea_address, 1000000, 1]}) %}
    let (tokenId) = mint(to, id)
    let (post_invocations) = getInvocations(id)
    assert post_invocations = 1

    let (tokenHash) = getTokenHash(tokenId) # 381304315295897251332778154035029083608405324224008374401192875262616584309
    assert tokenHash = token_hash_to_be

    assert tokenId = id * ONE_MILLION + pre_invocations

    return ()
end