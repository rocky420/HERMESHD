module parameters_mod

    use lib_vtk_io
    use MKL_VSL_TYPE
    use MKL_VSL

    include '/nfs/packages/opt/Linux_x86_64/openmpi/1.6.3/intel13.0/include/mpif.h'

    integer, parameter :: rh=1, mx=2, my=3, mz=4, en=5
    integer, parameter :: pxx=6, pyy=7, pzz=8, pxy=9, pxz=10, pyz=11, nQ=11

    !===========================================================================
    ! Spatial resolution -- # grid cells and DG basis order
    !---------------------------------------------------------------------------
    ! The jump in accuracy b/w the linear basis (nbasis=4) and quadratic basis
    ! (nbasis=10) is much greater than jump b/w quadratic and cubic (nbasis=20).
    !   nbasis = 4:  {1,x,y,z}
    !   nbasis = 10: nbasis4  + {P_2(x),P_2(y),P_2(z), yz, zx, xy}
    !   nbasis = 20: nbasis10 + {xyz,xP2(y),yP2(x),xP2(z),
    !                                zP2(x),yP2(z),zP2(y),P3(x),P3(y),P3(z)}
    integer, parameter :: nx=80, ny=1, nz=1, ngu=0, nbasis=8, nbastot=27

    ! iquad: # of Gaussian quadrature points per direction. iquad should not be:
    !   < ipoly (max Legendre polynomial order used) --> unstable
    !   > ipoly+1 --> an exact Gaussian quadrature for Legendre poly used
    ! Thus there are only two cases of iquad for a given nbasis. Both give similar
    ! results although iquad = ipoly + 1 is formally more accurate.
    integer, parameter :: iquad=2, nedge=iquad
        ! nface: number of quadrature points per cell face.
        ! npg: number of internal points per cell.
        integer, parameter :: nface=iquad*iquad, npg=nface*iquad, nfe=2*nface
        integer, parameter :: npge=6*nface, nslim=npg+6*nface
    !---------------------------------------------------------------------------

    !===========================================================================
    ! TODO:  CLASSIFY THESE PARAMETERS, SEAN!!!
    !---------------------------------------------------------------------------
    ! Boundary condition parameters:
    !   * 0 for set_bc subroutine used to prescribe BCs
    !   * 1 for wall (vanishing normal velocities).
    !   * 2 for periodic (MPI does this for you).
    integer, parameter :: xlbc = 1, xhbc = 1
    integer, parameter :: ylbc = 2, yhbc = 2
    integer, parameter :: zlbc = 2, zhbc = 2

    integer, parameter :: ntout = 100, iorder = 2
    integer, parameter :: icid = 3       ! Flag to select initial conditions
    logical, parameter :: llns = .false. ! Do LLNS. False turns off fluctuations
    ! character (8), parameter :: outdir = 'data/mod'

    character (*), parameter :: datadir="data", outname="test_mod1_0"
    character (*), parameter :: outdir = trim(datadir//"/"//outname)

    ! Choose Riemann solver for computing fluxes.  Set chosen solver = 1.
    ! If all of them = 0, then LLF is used for fluxes.
        ! LLF is very diffusive for the hydro problem.  Roe and HLLC are much less
        ! diffusive than LLF and give very similar results with similar cpu overhead
        ! Only HLLC is setup to handle water EOS (ieos = 2)
    integer, parameter :: ihllc = 1, iroe = 0, ieos = 1

    ! to restart from a checkpoint, set iread to 1 or 2 (when using the odd/even scheme)
    integer, parameter :: iread = 0, iwrite = 0
    character (4), parameter :: fpre = 'Qout'
    logical, parameter :: resuming = .false.

    !===========================================================================
    ! Test problems
    !---------------------------------------------------------------------------

    ! real, parameter :: lx = 300., ly = 300., lz = 300./120.
    ! real, parameter :: tf = 10000.

    ! 2D Isentropic vortex (inviscid, incompressible)
    ! real, parameter :: lx = 1.0e1, ly = 1.0e1, lz = 1.0e1/120.
    ! real, parameter :: tf = 1.0e2
    ! real, parameter :: vis = 0.0, epsi = 5., clt = 2. ! 2 is default clt

    ! 1D Sod Shock Tube (inviscid, compressible)
    ! NOTE: must change to set_bc2 manually right now
    ! real, parameter :: lx = 1.0e6, ly = 5.0e5, lz = 1.0e6/120.
    ! real, parameter :: tf = 2.0e5
    ! real, parameter :: vis = 0.0, epsi = 5., clt = 2. ! 2 is default clt

    ! 2D Sod Shock Tube
    ! NOTE: must change to set_bc2 manually right now
    real, parameter :: lx = 1.0e6, ly = 1.0e6, lz = 1.0e6/120.
    real, parameter :: tf = 8.5e4  ! 1.7e5
    real, parameter :: vis = 0.0, epsi = 5., clt = 2. ! 2 is default clt

    ! 2D pipe flow around cylinder (viscous, incompressible)
    ! NOTE: must change to set_bc4 manually right now
    ! real, parameter :: lx = 2.2e6, ly = 4.1e5, lz = 1.0e6/120.
    ! real, parameter :: tf = 3.3e4  ! 3.3 s for original problem
    ! real, parameter :: vis = 1.0e-3, epsi = 5., clt = 2. ! vis = 0.001 orig prob

    !---------------------------------------------------------------------------

    !===========================================================================
    ! Constants, and physical and numerical parameters
    !---------------------------------------------------------------------------
    ! Useful constants
    real, parameter :: pi = 4.0*atan(1.0)
    real, parameter :: sqrt2 = 2.**0.5, sqrt2i = 1./sqrt2
    real, parameter :: c1d5 = 1./5., c1d3 = 1./3., c2d3 = 2./3., c4d3 = 4./3.

    ! Thermodynamic and transport parameters
    real, parameter :: mu = 2.
    real, parameter :: aindex = 5./3., aindm1 = aindex-1.0, cp = aindex/aindm1
    ! real, parameter :: vis = 1.e-1, epsi = 5., clt = 2. ! 2 is default clt

    ! Dimensional units -- expressed in MKS. NOTE: temperature (te0) in eV!
    real, parameter :: L0=1.0e-9, t0=1.0e-12, n0=3.32e28
        ! Derived units
        real, parameter :: v0 = L0/t0
        real, parameter :: p0 = mu*1.67e-27*n0*v0**2
        real, parameter :: te0=p0/n0/1.6e-19          ! NOTE: in eV (not K)!

    ! rh_min is a min density to be used for ideal gas EOS, rh_min is min density
    ! below which the pressure becomes negative for the MT water EOS.
    ! The DG-based subroutine "limiter" keeps density above rh_mult*rh_min.
    real, parameter :: rh_floor = 5.0e-6
    real, parameter :: T_floor = 0.026/te0
    real, parameter :: P_floor = T_floor*rh_floor
        ! Murnaghan-Tait EOS
        !   P = P_1*(density**7.2 - 1.) + P_base
        ! Note: the EOS for water is likely to be a critical player in getting the
        ! fluctuating hydrodynamics correct. There are much more sophisicated EOS's,
        ! some of which account for ionic solutions. Would be worthwhile to
        ! further investigate and experiment with different EOS's.
        real, parameter :: n_tm = 7.2  ! 7.2 (or 7.15) for water
        real, parameter :: P_1 = 2.15e9/n_tm/p0, P_base = 1.01e5/p0 ! atmo pressure
        real, parameter :: rh_mult = 1.01, rh_min = rh_mult*(1.0-P_base/P_1)**(1./n_tm)
    !---------------------------------------------------------------------------


    !===========================================================================
    ! Arrays for field variables, fluxes, inner integrals, and sources
    !---------------------------------------------------------------------------
    real, dimension(nx,ny,nz,nQ,nbasis) :: Q_r0, Q_r1, Q_r2, Q_r3
    real, dimension(nx,ny,nz,nQ,nbasis) :: glflux_r, source_r, integral_r

    real den0(nx,ny,nz),Ez0,Zdy(nx,ny,nz,npg) !eta(nx,ny,nz,npg)
    real flux_x(nface,1:nx+1,ny,nz,1:nQ)
    real flux_y(nface,nx,1:ny+1,nz,1:nQ)
    real flux_z(nface,nx,ny,1:nz+1,1:nQ)
    real cfrx(nface,nQ),cfry(nface,nQ),cfrz(nface,nQ)

    ! Boundary conditions
    real Qxhigh_ext(ny,nz,nface,nQ), Qxlow_int(ny,nz,nface,nQ)
    real Qxlow_ext(ny,nz,nface,nQ), Qxhigh_int(ny,nz,nface,nQ)
    real Qyhigh_ext(nx,nz,nface,nQ), Qylow_int(nx,nz,nface,nQ)
    real Qylow_ext(nx,nz,nface,nQ), Qyhigh_int(nx,nz,nface,nQ)
    real Qzhigh_ext(nx,ny,nface,nQ), Qzlow_int(nx,ny,nface,nQ)
    real Qzlow_ext(nx,ny,nface,nQ), Qzhigh_int(nx,ny,nface,nQ)
    !---------------------------------------------------------------------------


    !===============================================================================
    !---------------------------------------------------------------------------
    ! NOTE: this is new stuff!
    ! Stuff for random matrix generation
    !---------------------------------------------------------------------------
    real, parameter :: nu = epsi*vis
    real, parameter :: c2d3nu=c2d3*nu, c4d3nu=c4d3*nu

    real, parameter :: T_base     = 300.0/1.16e4/te0  ! system temperature (for isothermal assumption)
    real, parameter :: eta_base   = vis    ! dynamic viscosity
    real, parameter :: zeta_base  = 0.  ! bulk viscosity---will need to adjust this!
    real, parameter :: kappa_base = 1.e-1

    real, parameter :: eta_sd   = (2.*eta_base*T_base)**0.5  ! stdev of fluctuations for shear viscosity terms
    real, parameter :: zeta_sd  = (zeta_base*T_base/3.)**0.5  ! stdev of fluctuations for bulk viscosity term
    real, parameter :: kappa_sd = (2.*kappa_base*T_base**2)**0.5

    ! real GRM_x(nface, 1:nx+1, ny,     nz,     3,3)
    ! real GRM_y(nface, nx,     1:ny+1, nz,     3,3)
    ! real GRM_z(nface, nx,     ny,     1:nz+1, 3,3)
    ! real Sflux_x(nface, 1:nx+1, ny,     nz,     3,3)
    ! real Sflux_y(nface, nx,     1:ny+1, nz,     3,3)
    ! real Sflux_z(nface, nx,     ny,     1:nz+1, 3,3)
    real vsl_errcode
    TYPE (VSL_STREAM_STATE) :: vsl_stream

    integer, parameter :: vsl_brng   = VSL_BRNG_MCG31
    integer, parameter :: vsl_method = VSL_RNG_METHOD_GAUSSIAN_BOXMULLER
    real, parameter :: vsl_mean  = 0.0
    real, parameter :: vsl_sigma = 1.0
    !===============================================================================


    !===========================================================================
    ! TODO:  CLASSIFY THESE PARAMETERS, SEAN!!!
    !---------------------------------------------------------------------------
    logical MMask(nx,ny,nz),BMask(nx,ny,nz)
    real xcell(npg), ycell(npg), zcell(npg), xface(npge), yface(npge), zface(npge)
    integer ticks, count_rate, count_max
    real t1, t2, t3, t4, elapsed_time, t_start, t_stop, dtoriginal
        real t, dt, dti, tout, dtout, vf, sqrt_dVdt_i ! Inv sq-root of (dV*dt), dV = grid cell volume
        real loc_lxd,loc_lyd,loc_lzd,check_Iz,sl
        real dz, dy, dx, dxi, dyi, dzi
        real lxd,lxu,lyd,lyu,lzd,lzu
        real pin_rad,pin_height,rh_foil,rh_fluid
        real pin_rad_in,pin_rad_out,rim_rad
        real disk_rad,disk_height,foil_rad,buf_rad,buf_z,dish_height,foil_height
        real gpz_rad,rh_gpz,kappa

    integer mxa(3),mya(3),mza(3),kroe(nface),niter,iseed
    !---------------------------------------------------------------------------

    !===========================================================================
    ! Parameters relating to quadratures and basis functions
    !---------------------------------------------------------------------------
    real wgt1d(5), wgt2d(30), wgt3d(100), cbasis(nbastot)
    ! wgt1d: quadrature weights for 1-D integration
    ! wgt2d: quadrature weights for 2-D integration
    ! wgt3d: quadrature weights for 3-D integration

    real, dimension(nface,nbastot) :: bfvals_zp, bfvals_zm
    real, dimension(nface,nbastot) :: bfvals_yp, bfvals_ym
    real, dimension(nface,nbastot) :: bfvals_xp, bfvals_xm
    real bf_faces(nslim,nbastot), bfvals_int(npg,nbastot),xquad(20)
        real bval_int_wgt(npg,nbastot)
        real wgtbfvals_xp(nface,nbastot),wgtbfvals_xm(nface,nbastot)
        real wgtbfvals_yp(nface,nbastot),wgtbfvals_ym(nface,nbastot)
        real wgtbfvals_zp(nface,nbastot),wgtbfvals_zm(nface,nbastot)
        real wgtbf_xmp(nface,2,nbastot),wgtbf_ymp(nface,2,nbastot),wgtbf_zmp(nface,2,nbastot)
        real sumx,sumy,sumz
        integer i2f,i01,i2fa

        ! Basis function flags
        integer, parameter :: kx=2,ky=3,kz=4,kyz=5,kzx=6,kxy=7,kxyz=8
        integer, parameter :: kxx=9,kyy=10,kzz=11
        integer, parameter :: kyzz=12,kzxx=13,kxyy=14,kyyz=15,kzzx=16,kxxy=17
        integer, parameter :: kyyzz=18,kzzxx=19,kxxyy=20,kyzxx=21,kzxyy=22,kxyzz=23
        integer, parameter :: kxyyzz=24,kyzzxx=25,kzxxyy=26,kxxyyzz=27
    !---------------------------------------------------------------------------

    !===========================================================================
    ! VTK output parameters
    !---------------------------------------------------------------------------
    integer, parameter :: nvtk=1 ! was 2
    integer, parameter :: nvtk2=nvtk*nvtk, nvtk3=nvtk*nvtk*nvtk
    integer(I4P), parameter :: nnx=nx*nvtk, nny=ny*nvtk, nnz=nz*nvtk
    real, dimension(nvtk3,nbastot) :: bfvtk, bfvtk_dx, bfvtk_dy, bfvtk_dz
    real xgrid(20),dxvtk,dyvtk,dzvtk
    !---------------------------------------------------------------------------

    !===========================================================================
    ! MPI definitions
    !---------------------------------------------------------------------------
    !   print_mpi is sets the MPI rank that will do any printing to console
    integer :: mpi_nx=16, mpi_ny=1, print_mpi=0
        integer iam,ierr,mpi_nz,numprocs,reorder,cartcomm,mpi_P,mpi_Q,mpi_R
        integer dims(3),coords(3),periods(3),nbrs(6),reqs(4),stats(MPI_STATUS_SIZE,4)
        integer,parameter:: NORTH=1,SOUTH=2,EAST=3,WEST=4,UP=5,DOWN=6,MPI_TT=MPI_REAL4
    !---------------------------------------------------------------------------

    real cflm

contains

    !-----------------------------------------------------------
    !   Return the x coordinate of (the center of) cell i
    !     Note: based on the location of this MPI domain (loc_lxd)
        real function xc(i)
            integer i
            xc = loc_lxd + (i - 0.5)*dx
        end function xc

    !-----------------------------------------------------------

        real function yc(j)
            integer j
            yc = loc_lyd + (j - 0.5)*dy
        end function yc

    !-----------------------------------------------------------

        real function zc(k)
            integer k
            zc = loc_lzd + (k - 0.5)*dz
        end function zc

    !-----------------------------------------------------------

        real function rz(i,j)
            integer i,j
            rz = sqrt(yc(j)**2)
        end function rz

    !-----------------------------------------------------------

        real function r(i,j)
            integer i,j,k
            r = sqrt(xc(i)**2 + yc(j)**2)
        end function r

    !-----------------------------------------------------------

        real function theta(i,j)
            integer i,j
            theta = atan2(yc(j),xc(i))
        end function theta

    !-----------------------------------------------------------

        real function xvtk(i)
            integer i
            xvtk = loc_lxd + (i - 0.5)*dxvtk
        end function xvtk

    !-----------------------------------------------------------

        real function yvtk(j)
            integer j
            yvtk = loc_lyd + (j - 0.5)*dyvtk
        end function yvtk

    !-----------------------------------------------------------

        real function zvtk(k)
            integer k
            zvtk = loc_lzd + (k - 0.5)*dzvtk
        end function zvtk

    !-----------------------------------------------------------

        real function rvtk(i,j)
            integer i,j,k
            rvtk = sqrt(xvtk(i)**2 + yvtk(j)**2)
        end function rvtk

    !-----------------------------------------------------------

        real function thetavtk(i,j)
            integer i,j
            thetavtk = atan2(yvtk(j),xvtk(i))
        end function thetavtk

    !-----------------------------------------------------------

end module parameters_mod
